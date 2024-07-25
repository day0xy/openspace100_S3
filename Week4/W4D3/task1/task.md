重新修改 MyWallet 合约的 transferOwernship 和 auth 逻辑，使用 solidity 内联汇编方式来 set 和 get owner 地址。

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MyWallet {
    string public name;
    mapping(address => bool) private approved;
    address public owner;

    modifier auth {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor(string memory _name) {
        name = _name;
        owner = msg.sender;
    }

    function transferOwnership(address _addr) public auth {
        require(_addr != address(0), "New owner is the zero address");
        require(owner != _addr, "New owner is the same as the old owner");
        owner = _addr;
    }
}
```
