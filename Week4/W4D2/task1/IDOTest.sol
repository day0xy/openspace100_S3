// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../src/IDO.sol";

contract TestToken is ERC20 {
    constructor() ERC20("TestToken", "TTK") {
        _mint(msg.sender, 1000000 * 1e18);
    }
}

contract TestTokenIDOTest is Test {
    TestTokenIDO public ido;
    TestToken public token;
    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        token = new TestToken();
        ido = new TestTokenIDO(
            address(token),
            100000 * 1e18,
            block.timestamp,
            block.timestamp + 10 days,
            owner
        );
        token.transfer(address(ido), 100000 * 1e18);
    }

    function testStartPresale() public {
        vm.expectEmit(false, false, false, false);
        emit PresaleStarted();
        vm.prank(owner);
        ido.startPresale();
        assert(ido.isPresaleActive() == true);
    }

    function testPresale() public {
        vm.expectEmit(false, false, false, false);
        emit PresaleStarted();
        vm.prank(owner);
        ido.startPresale();

        vm.expectEmit(true, false, false, false);
        emit Presale(user1, 0.05 ether);

        vm.deal(user1, 0.05 ether);
        vm.prank(user1);
        ido.presale{value: 0.05 ether}();

        assert(ido.totalRaised() == 0.05 ether);
        assert(ido.funded(user1) == 0.05 ether);
        assertEq(token.balanceOf(user1), 0.05 ether / PRESALE_PRICE);
    }

    function testClaimTokens() public {
        vm.prank(owner);
        ido.startPresale();
        vm.deal(user1, 100 ether);

        // 模拟募集资金达到100 ether
        for (uint256 i = 0; i < 1000; i++) {
            vm.prank(user1);
            ido.presale{value: 0.1 ether}();
        }
        // 设置时间为募集结束时间
        vm.warp(block.timestamp + 12 days);

        vm.expectEmit(true, false, false, false);
        emit TokensClaimed(
            user1,
            100000 * 1e18 * (ido.funded(user1) / ido.totalRaised())
        );
        vm.prank(user1);
        ido.claimTokens();

        //TODO: 检查用户领取后的TOKEN余额,目前无法检查
        assertEq(ido.funded(user1), 0);
    }

    function testClaimRefund() public {
        vm.prank(owner);
        ido.startPresale();
        vm.deal(user1, 0.05 ether);
        vm.prank(user1);
        ido.presale{value: 0.05 ether}();

        vm.warp(block.timestamp + 12 days);

        vm.prank(user2);
        vm.expectRevert("no refund available");
        ido.claimRefund();

        vm.prank(user1);
        ido.claimRefund();

        assertEq(ido.funded(user1), 0);
        assertEq(user1.balance, 0.05 ether);
    }

    function testWithdrawFunds() public {
        vm.prank(owner);
        ido.startPresale();
        vm.deal(user1, 100 ether);

        // 模拟募集资金达到100 ether
        for (uint256 i = 0; i < 1000; i++) {
            vm.prank(user1);
            ido.presale{value: 0.1 ether}();
        }

        vm.warp(block.timestamp + 12 days);
        vm.prank(owner);
        ido.withdrawFunds();

        // assert(address(owner).balance == 100 ether);
    }

    //项目方这次预售的tokem总量
    uint256 public totalPresaleAmount;

    //预售价格
    uint256 constant PRESALE_PRICE = 0.001 ether;
    //募集资金的期望值
    uint256 constant RAISE_LIMIT = 100 ether;
    //募集资金的最大值
    uint256 constant RAISE_CAP = 200 ether;
    //最小购买金额
    uint256 constant MIN_BUY = 0.01 ether;
    //最大购买金额
    uint256 constant MAX_BUY = 0.1 ether;
    //预售时间
    uint256 public startTime;
    uint256 public endTime;
    //募集的总金额
    uint256 public totalRaised = 0;

    event PresaleStarted();
    event Presale(address indexed user, uint256 amount);
    event TokensClaimed(address indexed user, uint256 tokens);
    event RefundClaimed(address indexed user, uint256 amount);
}
