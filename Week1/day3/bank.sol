// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract Bank {
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    address public admin;
    address[] private users;
    address[3] public topDepositors;
    uint256[3] public topDeposits;

    constructor() {
        admin = msg.sender;
    }

    // 映射存款
    mapping(address => uint256) private deposits;

    // 存钱函数
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");

        // 判断是否为第一次存款
        if (deposits[msg.sender] == 0) {
            users.push(msg.sender);
        }

        deposits[msg.sender] += msg.value;

        // 更新排名
        updateTop3Depositors(msg.sender, deposits[msg.sender]);

        // 触发存钱事件
        emit Deposit(msg.sender, msg.value);
    }

    // 取钱函数
    function withdraw(uint256 amount) external {
        if (msg.sender == admin) {
            // 管理员取出所有的钱
            uint256 allDeposits = address(this).balance;
            (bool success, ) = admin.call{value: allDeposits}("");
            require(success, "Admin failed to withdraw all deposits");

            /*
                todo: 所有用户的余额归零，清空top3排序数组的数据            
            */
            emit Withdraw(admin, allDeposits);
        } else {
            require(amount > 0, "Withdraw amount must be greater than zero");
            require(deposits[msg.sender] >= amount, "Insufficient balance");

            deposits[msg.sender] -= amount;

            // 用户取款
            (bool success, ) = msg.sender.call{value: amount}("");
            require(success, "Transfer failed");

            // 更新排名
            updateTop3Depositors(msg.sender, deposits[msg.sender]);
            emit Withdraw(msg.sender, amount);
        }
    }

    // 用户查询存款
    function getDeposits(address user) external view returns (uint256) {
        return deposits[user];
    }

    // 更新存款前三名的内部函数
    function updateTop3Depositors(address depositor, uint256 amount) internal {
        if (amount > topDeposits[0]) {
            topDepositors[2] = topDepositors[1];
            topDeposits[2] = topDeposits[1];

            topDepositors[1] = topDepositors[0];
            topDeposits[1] = topDeposits[0];

            topDepositors[0] = depositor;
            topDeposits[0] = amount;
        } else if (amount > topDeposits[1]) {
            topDepositors[2] = topDepositors[1];
            topDeposits[2] = topDeposits[1];

            topDepositors[1] = depositor;
            topDeposits[1] = amount;
        } else if (amount > topDeposits[2]) {
            topDepositors[2] = depositor;
            topDeposits[2] = amount;
        }
    }

    // 获取当前前3名存款人的信息
    function getTop3Depositors() external view returns (address[3] memory, uint256[3] memory) {
        return (topDepositors, topDeposits);
    }
}