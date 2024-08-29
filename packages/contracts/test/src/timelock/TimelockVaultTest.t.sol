// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { TimelockVault } from "@test/src/timelock/TimelockVault.s.sol";
import { ITimelock } from "@test/src/interfaces/ITimelock.s.sol";
import { TimelockTest } from "@test/src/timelock/TimelockTest.t.sol";

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SimpleToken } from "@test/test/token/SimpleToken.t.sol";

contract TimelockVaultTest is TimelockTest {
    ERC20 private underlyingAsset;

    function setUp() public {
        // Setup the underlying asset token and mint some to the owner
        vm.startPrank(owner);
        underlyingAsset = new SimpleToken(initialSupply);
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
