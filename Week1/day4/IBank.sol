// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IBank {
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    //public变量的getter函数
    function admin() external view returns (address);

    //public变量的getter函数
    function topDepositors(uint256 index) external view returns (address);

    function deposit() external payable;

    function withdraw(uint256 amount) external;

    function getDeposit(address user) external view returns (uint256);
}
