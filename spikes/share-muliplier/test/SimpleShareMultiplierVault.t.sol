// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../contracts/SimpleToken.sol";
import "../contracts/SimpleShareMultiplierVault.sol";

contract SimpleShareMultiplierVaultTest is Test {
  SimpleToken public token;
  SimpleShareMultiplierVault public vault;

  function setUp() public {
    token = new SimpleToken(1000);
    vault = new SimpleShareMultiplierVault(token, "SimpleShareMultiplierVault", "xSIM");
  }

  function test() public {
    token.mint(address(vault), 1000);
    require(token.balanceOf(address(vault)) == 1000);
  }
}
