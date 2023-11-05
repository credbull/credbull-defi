// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../contracts/SimpleTokenVesting.sol";
import "../contracts/SimpleToken.sol";

contract SimpleTokenVestingTest is Test {
  SimpleToken public token;
  SimpleTokenVesting public lock;

  function setUp() public {
    token = new SimpleToken(1000);
    lock = new SimpleTokenVesting(address(this), uint64(block.timestamp), 1);
  }

  function testShouldNotReleaseVesting() public {
    token.mint(address(lock), 1000);
    lock.release(address(token));
    require(lock.released(address(token)) == 0);
  }

  function testShouldReleaseVesting() public {
    token.mint(address(lock), 1000);
    vm.warp(block.timestamp + 2);
    lock.release(address(token));
    require(lock.released(address(token)) == 1000);
  }
}
