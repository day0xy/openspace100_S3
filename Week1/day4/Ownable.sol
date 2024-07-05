// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IBank.sol";
contract Ownable {
    address public admin;
    event Received(uint256 indexed amount);

    receive() external payable {
        emit Received(msg.value);
    }

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "caller is not the admin");
        _;
    }

    //Ownable合约调用BigBank的withdraw()
    function ownableWithdraw(
        address bankAddress,
        uint256 amount
    ) external onlyAdmin {
        //传入BigBank合约地址，调用其withdraw方法
        IBank(bankAddress).withdraw(amount);
    }
}
