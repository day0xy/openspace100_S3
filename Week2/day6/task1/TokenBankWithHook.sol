// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// 定义 TokenRecipient 接口
interface TokenRecipient {
    function tokensReceived(address from, uint256 amount) external returns (bool);
}

contract TokenBank is TokenRecipient {
    IERC20 public token;

    event Deposit(address indexed user, uint256 indexed amount);
    event Withdraw(address indexed user, uint256 indexed amount);

    // 记录每个地址的存入数量
    mapping(address => uint256) public deposits;

    // 构造函数，传入 BaseERC20 的合约地址
    constructor(address tokenAddress) {
        token = IERC20(tokenAddress);
    }

    // 存款函数
    function deposit(uint256 amount) public {
        require(token.transferFrom(msg.sender, address(this), amount), "error, transfer failed");
        deposits[msg.sender] += amount;
        emit Deposit(msg.sender, amount);
    }

    // 提款函数
    function withdraw(uint256 amount) public {
        require(amount > 0, "require amount > 0");
        require(deposits[msg.sender] >= amount, "error, insufficient deposits to withdraw");

        deposits[msg.sender] -= amount;
        require(token.transfer(msg.sender, amount), "error, token failed to transfer");
        emit Withdraw(msg.sender, amount);
    }

    // 查看账户的存款余额
    function balanceOf(address account) public view returns (uint256) {
        return deposits[account];
    }

    // 实现 TokenRecipient 接口中的 tokensReceived 方法
    function tokensReceived(address from, uint256 amount) external override returns (bool) {
        // 确保调用者是指定的 ERC20 代币合约
        require(msg.sender == address(token), "error, caller is not the token contract");
        
        // 更新存款记录
        deposits[from] += amount;
        
        // 触发存款事件
        emit Deposit(from, amount);
        
        return true;
    }
}