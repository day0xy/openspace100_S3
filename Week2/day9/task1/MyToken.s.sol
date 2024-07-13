// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "forge-std/Script.sol";
import "../src/MyToken.sol";
contract MyTokenScript is Script {
    function run() external {
        vm.startBroadcast();

        MyToken mytoken = new MyToken("MyToken", "MT");

        vm.stopBroadcast();
        console.log("MyToken deployed at:", address(mytoken));
    }
}
