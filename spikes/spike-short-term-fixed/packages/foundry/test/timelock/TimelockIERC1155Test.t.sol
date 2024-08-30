// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { TimelockIERC1155 } from "@credbull/contracts/timelock/TimelockIERC1155.sol";
import { ITimelock } from "@credbull/contracts/interfaces/ITimelock.sol";
import { TimelockTest } from "@test/timelock/TimelockTest.t.sol";

contract TimelockIERC1155Test is TimelockTest {
    function setUp() public {
        timelock = new TimelockIERC1155(owner, lockReleasePeriod);
    }

    function toImpl(ITimelock _timelock) internal pure returns (TimelockIERC1155) {
        // Simulate time passing by setting the current time periods elapsed
        TimelockIERC1155 timelockImpl = TimelockIERC1155(address(_timelock));
        return timelockImpl;
    }

    function warpToPeriod(ITimelock _timelock, uint256 timePeriod) internal override {
        // Simulate time passing by setting the current time periods elapsed
        TimelockIERC1155 timelockImpl = toImpl(_timelock);
        timelockImpl.setCurrentPeriod(timePeriod);
    }

    function test__TimelockIERC1155__RolloverUnlockedPartial() public virtual {
        uint256 depositAmount = 1000;
        uint256 rolloverAmount = 500;

        // Alice locks the tokens using the Timelock contract
        vm.startPrank(owner);
        timelock.lock(alice, lockReleasePeriod, depositAmount);
        vm.stopPrank();

        // Advance the period to make the tokens unlockable
        warpToPeriod(timelock, lockReleasePeriod);

        uint256 unlockableAmount = timelock.previewUnlock(alice, lockReleasePeriod);
        assertEq(unlockableAmount, depositAmount, "All tokens should be unlockable after the lock period");

        // Perform a rollover of the unlocked tokens
        vm.startPrank(owner);
        timelock.rolloverUnlocked(alice, lockReleasePeriod, rolloverAmount);
        vm.stopPrank();

        // Check that the rolled-over tokens are locked under the new period
        uint256 lockedAmountAfterRollover = timelock.getLockedAmount(alice, rolloverPeriod);
        assertEq(lockedAmountAfterRollover, rolloverAmount, "Incorrect locked amount after rollover");

        // Check that the remaining tokens in the original period are reduced
        uint256 remainingUnlockableAmount = timelock.previewUnlock(alice, lockReleasePeriod);
        assertEq(remainingUnlockableAmount, depositAmount - rolloverAmount, "Incorrect remaining unlockable amount after rollover");
    }
}
