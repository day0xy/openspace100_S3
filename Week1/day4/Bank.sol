// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IBank.sol";

contract Bank is IBank {
    address public admin;
    address[] public topDepositors;

    constructor() {
        admin = msg.sender;
    }

    // 映射存款
    mapping(address => uint256) private deposits;

    receive() external payable {
        deposit();
    }

    // 存钱函数
    function deposit() public payable virtual {
        require(msg.value > 0, "Deposit amount must be greater than zero");

        deposits[msg.sender] += msg.value;

        // 更新排名
        updateTop3Depositors(msg.sender);

        // 触发存钱事件
        emit Deposit(msg.sender, msg.value);
    }

    // 取钱函数
    function withdraw(uint256 amount) external virtual {
        if (msg.sender == admin) {
            // 管理员取出所有的钱
            uint256 allDeposits = address(this).balance;
            (bool success,) = admin.call{value: allDeposits}("");
            require(success, "Admin failed to withdraw all deposits");

            emit Withdraw(admin, allDeposits);
        } else {
            require(amount > 0, "Withdraw amount must be greater than zero");
            require(deposits[msg.sender] >= amount, "Insufficient balance");

            deposits[msg.sender] -= amount;

            // 用户取款
            (bool success,) = msg.sender.call{value: amount}("");
            require(success, "Transfer failed");

            // 更新排名
            updateTop3Depositors(msg.sender);
            emit Withdraw(msg.sender, amount);
        }
    }

    // 更新存款前三名
    function updateTop3Depositors(address depositor) internal {
        bool exists = false;

        for (uint256 i = 0; i < topDepositors.length; i++) {
            if (topDepositors[i] == depositor) {
                exists = true;
                break;
            }
        }

        if (!exists) {
            topDepositors.push(depositor);
        }

        // 冒泡排序，按存款金额排序
        for (uint256 i = 0; i < topDepositors.length - 1; i++) {
            for (uint256 j = 0; j < topDepositors.length - i - 1; j++) {
                if (deposits[topDepositors[j]] < deposits[topDepositors[j + 1]]) {
                    address temp = topDepositors[j];
                    topDepositors[j] = topDepositors[j + 1];
                    topDepositors[j + 1] = temp;
                }
            }
        }

        if (topDepositors.length > 3) {
            topDepositors.pop();
        }
    }

    // 获取某个用户的存款金额
    function getDeposit(address user) external view returns (uint256) {
        return deposits[user];
    }
}
