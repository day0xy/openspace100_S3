// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract TokenBank {
    IERC20 public token;

    event Deposit(address indexed user, uint256 indexed amount);
    event Withdraw(address indexed user, uint256 indexed amount);

    // 记录每个地址的存入数量
    mapping(address => uint256) public deposits;

    // 构造函数，传入BaseERC20的合约地址
    constructor(address tokenAddress) {
        token = IERC20(tokenAddress);
    }

    // 存款函数
    function deposit(uint256 amount) public {
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "error,transfer failed"
        );
        deposits[msg.sender] += amount;
        emit Deposit(msg.sender, amount);
    }

    // 提款函数
    function withdraw(uint256 amount) public {
        require(amount > 0, "require amount > 0");
        require(
            deposits[msg.sender] >= amount,
            "error,insufficient deposits to withdraw"
        );

        deposits[msg.sender] -= amount;
        require(
            token.transfer(msg.sender, amount),
            "error,token failed to transfer"
        );
        emit Withdraw(msg.sender, amount);
    }

    // 查看账户的存款余额
    function balanceOf(address account) public view returns (uint256) {
        return deposits[account];
    }
}
