// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract TokenBank {
    IERC20 public token;
    ERC20Permit public permitToken;

    event Deposit(address indexed user, uint256 indexed amount);
    event Withdraw(address indexed user, uint256 indexed amount);

    // 记录每个地址的存入数量
    mapping(address => uint256) public deposits;

    // 构造函数，传入BaseERC20的合约地址
    constructor(address tokenAddress) {
        token = IERC20(tokenAddress);
        permitToken = ERC20Permit(tokenAddress);
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

    // permitDeposit 函数
    function permitDeposit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        // 使用 permit 方法进行授权
        permitToken.permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );

        // 授权成功后进行存款操作
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "error, transfer failed"
        );
        deposits[msg.sender] += amount;
        emit Deposit(msg.sender, amount);
    }
}
