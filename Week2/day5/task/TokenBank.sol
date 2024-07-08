// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./ERC20.sol";

contract TokenBank {
    
    mapping(address => uint256) balances;

    function deposit(uint256 amount) public returns (bool) {
        balances[msg.sender] += amount;
        return true;
    }

    function withdraw(address to) public returns (bool) {
        return true;
    }
}
