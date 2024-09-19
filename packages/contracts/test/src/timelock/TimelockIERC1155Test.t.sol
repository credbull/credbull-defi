// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { TimelockIERC1155 } from "@credbull/timelock/TimelockIERC1155.sol";
import { ITimelock } from "@credbull/timelock/ITimelock.sol";
import { TimelockTest } from "@test/src/timelock/TimelockTest.t.sol";

contract SimpleTimelockIERC1155 is TimelockIERC1155 {
    uint256 public myLockDuration;
    uint256 public currentPeriodElapsed = 0;

    constructor(address _initialOwner, uint256 _lockDuration) TimelockIERC1155(_initialOwner) {
        myLockDuration = _lockDuration;
    }

    function lockDuration() public view override returns (uint256 lockDuration_) {
        return myLockDuration;
    }

    function currentPeriod() public view override returns (uint256 currentPeriod_) {
        return currentPeriodElapsed;
    }

    function setCurrentPeriod(uint256 currentPeriod_) public override {
        currentPeriodElapsed = currentPeriod_;
    }
}

contract TimelockIERC1155Test is TimelockTest {
    function setUp() public {
        timelock = new SimpleTimelockIERC1155(owner, lockReleasePeriod);
    }

    function toImpl(ITimelock _timelock) internal pure returns (TimelockIERC1155) {
        // Simulate time passing by setting the current time periods elapsed
        TimelockIERC1155 timelockImpl = SimpleTimelockIERC1155(address(_timelock));
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

        TimelockIERC1155 rollable = toImpl(timelock);

        // Perform a rollover of the unlocked tokens
        vm.startPrank(owner);
        rollable.rolloverUnlocked(alice, lockReleasePeriod, rolloverAmount);
        vm.stopPrank();

        // Check that the rolled-over tokens are locked under the new period
        uint256 lockedAmountAfterRollover = timelock.lockedAmount(alice, rolloverPeriod);
        assertEq(lockedAmountAfterRollover, rolloverAmount, "Incorrect locked amount after rollover");

        // Check that the remaining tokens in the original period are reduced
        uint256 remainingUnlockableAmount = timelock.previewUnlock(alice, lockReleasePeriod);
        assertEq(
            remainingUnlockableAmount,
            depositAmount - rolloverAmount,
            "Incorrect remaining unlockable amount after rollover"
        );
    }
}
