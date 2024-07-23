// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

//实现一个ERC20 TOKEN
contract testToken is ERC20 {
    constructor() ERC20("testToken", "TT") {
        _mint(msg.sender, 1e6 * 10 ** decimals());
    }
}

contract IDO {
    function presale() public {}

    function claim() public {}
}
