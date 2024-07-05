// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Bank.sol";

contract BigBank is Bank {
    // 映射存款
    mapping(address => uint256) private deposits;
    // 修饰器，权限控制deposit()
    modifier limitedBalance() {
        require(
            msg.value > 0.001 ether,
            "error! Deposit amount must be at least 0.001 ether"
        );
        _;
    }

    // 修饰器，权限控制changeAdmin(), withdraw()
    modifier onlyAdmin() {
        require(msg.sender == admin, "error! Caller is not the admin");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    // 存钱函数
    function deposit() public payable virtual override limitedBalance {
        deposits[msg.sender] += msg.value;

        // 更新排名
        updateTop3Depositors(msg.sender);

        // 触发存钱事件
        emit Deposit(msg.sender, msg.value);
    }

    // 管理员取钱函数
    function withdraw(uint256 amount) external virtual override onlyAdmin {
        require(amount > 0, "error! Withdraw amount must be greater than zero");
        uint256 allDeposits = address(this).balance;
        require(
            amount <= allDeposits,
            "error! Insufficient deposits in the bank"
        );

        // 取出amount数量的钱
        (bool success, ) = admin.call{value: amount}("");
        require(success, "Admin failed to withdraw deposits");

        emit Withdraw(admin, amount);
    }

    // 转移管理员权限
    function changeAdmin(address newAdminAddress) external onlyAdmin {
        require(
            newAdminAddress != address(0),
            "error! newAdminAddress is 0 address"
        );
        admin = newAdminAddress;
    }

    //无需重写
    // function updateTop3Depositors(address depositor) internal {}
}
