//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import { MockUSDC } from "@credbull-spike/contracts/chai/MockUSDC.sol";

contract UserGenerator is Test {
  uint256 private counter;

  function generateUser(
    MockUSDC usdc
  ) internal returns (address) {
    ++counter;

    address user = address(uint160(uint256(keccak256(abi.encodePacked(counter, block.timestamp, block.prevrandao)))));

    usdc.mint(user, 100000 * 10 ** usdc.decimals());

    return user;
  }
}
