// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../contracts/SimpleToken.sol";
import "../contracts/SimpleShareMultiplierVault.sol";

contract SimpleShareMultiplierVaultTest is Test {
    SimpleToken public token;
    SimpleShareMultiplierVault public vault;

    function setUp() public {
        token = new SimpleToken(2000);
        vault = new SimpleShareMultiplierVault(token, "SimpleShareMultiplierVault", "xSIM");
    }

    function testDepositWithMultiplier() public {
        token.mint(msg.sender, 1000);
        token.approve(address(vault), 1000);

        vault.addMultiplier(msg.sender, 2);
        vault.deposit(1000, msg.sender);

        require(token.balanceOf(address(vault)) == 1000);
        require(vault.balanceOf(address(msg.sender)) == 2000);
    }

    function testMintWithMultiplier() public {
        token.mint(msg.sender, 1000);
        token.approve(address(vault), 1000);

        vault.addMultiplier(msg.sender, 2);
        vault.mint(2000, msg.sender);

        require(token.balanceOf(address(vault)) == 1000);
        require(vault.balanceOf(address(msg.sender)) == 2000);
    }

    function testDepositWithoutMultiplier() public {
        token.mint(msg.sender, 1000);
        token.approve(address(vault), 1000);

        vault.deposit(1000, msg.sender);

        require(token.balanceOf(address(vault)) == 1000);
        require(vault.balanceOf(address(msg.sender)) == 1000);
    }

    function testMintWithoutMultiplier() public {
        token.mint(msg.sender, 1000);
        token.approve(address(vault), 1000);

        vault.mint(1000, msg.sender);

        require(token.balanceOf(address(vault)) == 1000);
        require(vault.balanceOf(address(msg.sender)) == 1000);
    }
}
