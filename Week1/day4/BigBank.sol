// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "./Bank.sol";

contract BigBank is Bank {
    
    modifier limitedBalance() {
        require(msg.value >= 0.001 ether);
        _;
    }

    receive() external payable {
        deposit();
    }

    // 存钱函数
    function deposit() public payable override limitedBalance {
        require(msg.value > 0, "Deposit amount must be greater than zero");

        deposits[msg.sender] += msg.value;

        // 更新排名
        updateTop3Depositors(msg.sender);

        // 触发存钱事件
        emit Deposit(msg.sender, msg.value);
    }
}
