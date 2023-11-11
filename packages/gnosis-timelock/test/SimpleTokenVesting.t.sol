// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/SimpleTokenVesting.sol";
import "../src/test/SimpleToken.sol";

contract SimpleTokenVestingTest is Test {
  SimpleToken public token;
  SimpleTokenVesting public vault;

  function setUp() public {
    token = new SimpleToken(1000);
    vault = new SimpleTokenVesting(token, "SimpleTokenVesting", "xSIM", uint64(block.timestamp), 1);
  }

  function testShouldReleaseVesting() public {
    address john = makeAddr("John");
    token.mint(john, 1000);

    vm.startPrank(john);
    token.approve(address(vault), 2000);
    vault.deposit(1000, john);

    require(vault.totalAssets() == 1000);
    require(token.balanceOf(address(vault)) == 1000);
    require(vault.balanceOf(address(john)) == 1000);

    vm.warp(block.timestamp + 2);
    vault.withdraw(1000, john, john);

    require(token.balanceOf(address(vault)) == 0);
    require(token.balanceOf(address(john)) == 1000);
    require(vault.balanceOf(address(john)) == 0);
  }

  function testShouldNotReleaseVesting() public {
    address john = makeAddr("John");
    token.mint(john, 1000);

    vm.startPrank(john);
    token.approve(address(vault), 2000);
    vault.deposit(1000, john);

    vm.expectRevert(SimpleTokenVesting.SharesInVestingPeriod.selector);
    vault.withdraw(1000, john, john);
  }
}
