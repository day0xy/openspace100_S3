// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {Test, console} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Market} from "../src/Market.sol";

// 创建一个 mock ERC20 代币合约用于测试
contract MockERC20 is ERC20 {
    constructor() ERC20("Mock Token", "MKT") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}

// 创建一个 mock ERC721 NFT 合约用于测试
contract MockERC721 is ERC721 {
    uint256 private _tokenId = 0;

    constructor() ERC721("Mock NFT", "MNFT") {}

    function mint(address to) external {
        _mint(to, _tokenId);
        _tokenId++;
    }
}

contract MarketTest is Test {
    Market market;
    MockERC20 token;
    MockERC721 nft;

    struct Listing {
        address seller;
        uint256 price;
    }
    mapping(uint256 => Listing) public listings;

    event NFTListed(
        address indexed seller,
        uint256 indexed tokenId,
        uint256 price
    );

    event NFTPurchased(
        address indexed buyer,
        uint256 indexed tokenId,
        uint256 price
    );

    address seller = makeAddr("seller");
    address notNFTowner = makeAddr("notNFTowner");
    address buyer = makeAddr("buyer");
    address insufficientBuyer = makeAddr("insufficientBuyer");
    uint256 public initialBalance = 1000;
    uint256 public testPrice = 100;

    function setUp() public {
        token = new MockERC20();
        nft = new MockERC721();
        market = new Market(token, nft);

        //给买家buyer发一些ERC20 token
        token.transfer(buyer, initialBalance);
        token.transfer(insufficientBuyer, 50);
        //给卖家seller铸造一些nft
        nft.mint(seller);

        vm.startPrank(seller);
        //seller授权nft给market合约
        nft.approve(address(market), 0);
        vm.stopPrank();

        //授权token给maket合约
        vm.prank(buyer);
        token.approve(address(market), testPrice);

        //这里测试余额不足的情况  test_buyNFT_insufficient_token()
        //授权token给maket合约
        vm.prank(insufficientBuyer);
        token.approve(address(market), 50);
    }

    //测试上架成功+事件
    function test_list_success() public {
        vm.prank(seller);

        vm.expectEmit(true, true, false, true);
        emit NFTListed(seller, 0, testPrice);
        market.list(0, testPrice);
        (address seller1, uint256 price) = market.listings(0);
        assertEq(seller1, seller);
        assertEq(price, testPrice);
        //确保转移所有权给market合约
        assertEq(nft.ownerOf(0), address(market));
    }

    // 测试调用者是NFT的所有者时成功
    function test_list_is_NFT_Owner() public {
        vm.prank(seller);
        market.list(0, testPrice);
        (address seller1, uint256 price) = market.listings(0);
        assertEq(seller1, seller);
        assertEq(price, testPrice);
        assertEq(nft.ownerOf(0), address(market));
    }

    // 测试调用者不是NFT的所有者时失败
    function test_list_not_NFT_Owner() public {
        vm.prank(notNFTowner);
        vm.expectRevert("caller is not the owner of the nft");
        market.list(0, testPrice);
    }

    // 测试价格为0时失败
    function test_list_price_is_zero() public {
        vm.prank(seller);
        vm.expectRevert("Price must be greater than 0");
        market.list(0, 0);
    }

    // 测试NFT未授权给Market时上架失败
    function test_list_not_approved() public {
        //取消授权approve
        vm.startPrank(seller);
        nft.approve(address(0), 0);

        vm.expectRevert("NFT not approved for transfer");
        market.list(0, testPrice);

        vm.stopPrank();
    }
    //测试重复上架时失败
    function test_list_already_listed() public {
        vm.prank(seller);
        market.list(0, testPrice);

        vm.prank(seller);
        vm.expectRevert();
        market.list(0, testPrice);
    }

    // 测试购买成功+事件
    function test_buyNFT_success() public {
        vm.prank(seller);
        market.list(0, testPrice);

        vm.prank(buyer);
        vm.expectEmit(true, true, false, true);
        emit NFTPurchased(buyer, 0, testPrice);
        market.buyNFT(0);
        //判断交易后的owner是否为buyer
        assertEq(nft.ownerOf(0), buyer);
        assertEq(token.balanceOf(buyer), 900);
        assertEq(token.balanceOf(seller), 100);
        //检查购买后，nft 0 的seller和price被重置
        (address seller1, uint256 price) = market.listings(0);
        assertEq(seller1, address(0));
        assertEq(price, 0);
    }

    //测试自己买自己的NFT失败
    function test_buyNFT_buy_own_nft() public {
        vm.prank(seller);
        market.list(0, testPrice);

        vm.expectRevert();
        market.buyNFT(0);
    }

    //测试NFT被重复购买时失败
    function test_buyNFT_buy_duplicate_nft() public {
        vm.prank(seller);
        market.list(0, testPrice);

        vm.prank(buyer);
        market.buyNFT(0);

        //重复购买
        vm.prank(buyer);
        vm.expectRevert();
        market.buyNFT(0);
    }

    //测试余额不足时购买失败
    function test_buyNFT_insufficient_token() public {
        vm.prank(seller);
        market.list(0, testPrice);

        vm.prank(insufficientBuyer);
        vm.expectRevert();
        market.buyNFT(0);
    }

    //测试未上架的NFT购买失败
    function test_buyNFT_not_listed() public {
        vm.prank(buyer);
        vm.expectRevert("NFT not listed for sale");
        market.buyNFT(0);
    }

    //模糊测试上架和购买
    function testFuzz_list_and_buyNFT(
        uint256 price,
        address randomAddress
    ) public {
        uint256 minValue = 10 ** 16; // 0.01 tokens
        uint256 maxValue = 10000 * 10 ** 18; // 10000 tokens
        vm.assume(price >= minValue && price <= maxValue);
        vm.assume(randomAddress != address(0));
        vm.assume(randomAddress != seller);

        // 给randomAddress发一些ERC20 token
        vm.prank(address(this));
        token.transfer(randomAddress, 10000000 * 10 ** 18);

        vm.prank(randomAddress);
        token.approve(address(market), 10000000 * 10 ** 18);

        vm.prank(seller);
        // 验证上架事件
        vm.expectEmit(true, true, false, true);
        emit NFTListed(seller, 0, price);
        // 随机使用 0.01-10000 Token价格上架NFT
        market.list(0, price);

        // 验证上架后的状态
        (address listedSeller, uint256 listedPrice) = market.listings(0);
        assertEq(listedSeller, seller);
        assertEq(listedPrice, price);
        assertEq(nft.ownerOf(0), address(market));

        // 随机使用任意Address购买NFT
        vm.prank(randomAddress);
        vm.expectEmit(true, true, false, true);
        emit NFTPurchased(randomAddress, 0, price);
        market.buyNFT(0);

        // 验证购买后的状态
        assertEq(nft.ownerOf(0), randomAddress);
        assertEq(token.balanceOf(randomAddress), 10000000 * 10 ** 18 - price);
        assertEq(token.balanceOf(seller), price);

        // 验证listing已被清除
        (address seller2, uint256 listedPrice2) = market.listings(0);
        assertEq(seller2, address(0));
        assertEq(listedPrice2, 0);
    }

    /**
    TODO:
    不可变测试
     */
}
