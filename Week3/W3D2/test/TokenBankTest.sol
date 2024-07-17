// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import "../src/TokenBank.sol";
import "../src/PermitToken.sol";

contract TokenBankTest is Test {
    TokenBank public tokenBank;
    PermitToken public permitToken;
    address public user;
    uint256 public userPrivateKey;

    function setUp() public {
        // 部署PermitToken合约
        permitToken = new PermitToken();

        // 部署TokenBank合约并传递PermitToken的地址
        tokenBank = new TokenBank(address(permitToken));

        // 使用Foundry的作弊码生成用户地址和私钥
        (user, userPrivateKey) = makeAddrAndKey("user");

        // 给用户转一些token
        permitToken.transfer(user, 100 ether);

        // 确保用户的余额已更新
        assertEq(permitToken.balanceOf(user), 100 ether);
    }

    function test_permitDeposit() public {
        bytes32 PERMIT_TYPEHASH = keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

        uint256 deadline = block.timestamp + 1 days;
        uint256 amount = 100 ether;

        // 获取签名哈希
        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                user,
                address(tokenBank),
                amount,
                0, // 初始nonce
                deadline
            )
        );

        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                permitToken.DOMAIN_SEPARATOR(),
                structHash
            )
        );

        // 使用生成的私钥进行签名
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, hash);

        // 模拟用户调用permitDeposit
        vm.prank(user);
        tokenBank.permitDeposit(amount, deadline, v, r, s);

        // 检查存款是否成功
        uint256 depositBalance = tokenBank.balanceOf(user);
        assertEq(depositBalance, amount);
    }
}
