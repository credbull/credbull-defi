// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { TimelockVault } from "@credbull-spike/contracts/ian/timelock/TimelockVault.sol";
import { ITimelock } from "@credbull-spike/contracts/ian/interfaces/ITimelock.sol";
import { TimelockTest } from "@credbull-spike-test/ian/timelock/TimelockTest.t.sol";

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SimpleUSDC } from "@credbull-spike/contracts/kk/SimpleUSDC.sol";

contract TimelockVaultTest is TimelockTest {
  ERC20 private underlyingAsset;

  function setUp() public {
    // Setup the underlying asset token and mint some to the owner
    vm.startPrank(owner);
    underlyingAsset = new SimpleUSDC(initialSupply);
    timelock = new TimelockVault(owner, underlyingAsset, "VaultToken", "VT", lockReleasePeriod);
    vm.stopPrank();
  }

  function toImpl(ITimelock _timelock) internal pure returns (TimelockVault timelockVault) {
    // Simulate time passing by setting the current time periods elapsed
    TimelockVault timelockImpl = TimelockVault(address(_timelock));

    return timelockImpl;
  }

  function warpToPeriod(ITimelock _timelock, uint256 timePeriod) internal override {
    // Simulate time passing by setting the current time periods elapsed
    TimelockVault timelockImpl = toImpl(_timelock);
    timelockImpl.setCurrentTimePeriodsElapsed(timePeriod);
  }
}
