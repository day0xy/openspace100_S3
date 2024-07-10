// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface TokenRecipient {
    function tokensReceived(address from, uint256 amount) external returns (bool);
}

contract MyToken is ERC20 {
    using Address for address;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function transferWithCallback(address recipient, uint256 amount) external returns (bool) {
        _transfer(_msgSender(), recipient, amount);

        if (recipient.code.length > 0) {
            bool rv = TokenRecipient(recipient).tokensReceived(_msgSender(), amount);
            require(rv, "No tokensReceived");
        }

        return true;
    }
}
