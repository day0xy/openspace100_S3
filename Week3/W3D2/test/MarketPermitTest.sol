// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {NFTMarket} from "../src/MarketPermit.sol";

contract MarketPermitTest is Test {
    NFTMarket market;
    MockERC20 token;
    MockERC721 nft;

    bytes signature;
    address public seller;
    address public buyer;
    address public whiteListSigner;
    uint256 signerPrivateKey;

    function setUp() public {
        market = new NFTMarket();
        token = new MockERC20();
        nft = new MockERC721();
        seller = makeAddr("seller");
        buyer = makeAddr("buyer");

        // 给 buyer 发送 1000 个代币
        token.transfer(buyer, 1000);

        nft.mint(seller);
        // seller 铸造 NFT 并授权 market
        vm.startPrank(seller);
        nft.setApprovalForAll(address(market), true);
        vm.stopPrank();

        // buyer 授权 token
        vm.startPrank(buyer);
        token.approve(address(market), 1000);
        vm.stopPrank();

        // 生成私钥并设置白名单签名者
        signerPrivateKey = uint256(keccak256("whiteListSignerPrivateKey")); // 生成一个私钥（仅用于测试）
        whiteListSigner = vm.addr(signerPrivateKey); // 从私钥生成地址
        market.setWhiteListSigner(whiteListSigner);

        // 生成白名单签名
        bytes32 wlHash = market.hashTypedDataV4(
            keccak256(abi.encode(market.getWLTypeHash(), buyer))
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, wlHash); // 使用生成的私钥进行签名
        signature = abi.encodePacked(r, s, v);
    }

    function test_permitBuy() public {
        uint256 tokenId = 0;
        uint256 deadline = block.timestamp + 1000;
        uint256 price = 100;

        vm.startPrank(seller);
        market.list(address(nft), tokenId, price, address(token), deadline);
        vm.stopPrank();

        vm.startPrank(buyer);
        market.permitBuy(address(nft), tokenId, signature);
        vm.stopPrank();

        assertEq(nft.ownerOf(tokenId), buyer);
        assertEq(token.balanceOf(seller), price);
    }

    struct Listing {
        address seller;
        uint256 price;
        address payToken;
        uint256 deadline;
    }

    event List(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address seller,
        address payToken,
        uint256 price,
        uint256 deadline
    );

    event BuyNFT(
        address seller,
        address indexed buyer,
        uint256 price,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    event Delist(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    event SetWhiteListSigner(address indexed signer);
}

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
