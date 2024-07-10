// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {Bank} from "../src/Bank.sol";

contract BankTest is Test {
    //初始化一个bank
    Bank bank;

    event Deposit(address indexed user, uint amount);

    function setUp() public {
        bank = new Bank();
    }

    function test_depositETH() public {
        address user = address(1);
        uint amount = 1 ether;
        vm.deal(user, amount);
        vm.prank(user);

        // 设置期待触发的事件
        vm.expectEmit(true, true, true, false);
        emit Deposit(user, amount);

        bank.depositETH{value: amount}();

        // 断言验证用户余额是否正确更新
        assertEq(bank.balanceOf(user), amount);
    }
}
