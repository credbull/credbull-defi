// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { TimelockIERC1155 } from "@test/test/timelock/TimelockIERC1155.t.sol";
import { ITimelock } from "@credbull/timelock/ITimelock.sol";
import { TimelockTest } from "@test/src/timelock/TimelockTest.t.sol";
import { TimerCheats } from "@test/test/timelock/TimerCheats.t.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract TimelockIERC1155Test is TimelockTest {
    function setUp() public {
        timelock = new SimpleTimelockIERC1155(owner, lockUntilDay1.releasePeriod);
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
        vm.prank(owner);
        timelock.lock(alice, lockUntilDay1.releasePeriod, lockUntilDay1.amount);

        // warp to releasePeriod
        warpToPeriod(timelock, lockUntilDay1.releasePeriod);

        uint256 unlockableAmount = timelock.maxUnlock(alice, lockUntilDay1.releasePeriod);
        assertEq(unlockableAmount, lockUntilDay1.amount, "all tokens should be unlockable after the lock period");

        TimelockIERC1155 rollable = toImpl(timelock);

        // rollover the unlocked tokens
        vm.prank(owner);
        rollable.rolloverUnlocked(alice, lockUntilDay1.releasePeriod, lockUntilDay2.amount);

        // check rolled-over tokens are locked under the new period
        uint256 lockedAmountAfterRollover = timelock.lockedAmount(alice, lockUntilDay2.releasePeriod);
        assertEq(lockedAmountAfterRollover, lockUntilDay2.amount, "incorrect locked amount after rollover");

        // check remaining tokens in the original period are reduced
        uint256 remainingUnlockableAmount = timelock.maxUnlock(alice, lockUntilDay1.releasePeriod);
        assertEq(
            remainingUnlockableAmount,
            lockUntilDay1.amount - lockUntilDay2.amount,
            "incorrect remaining unlockable amount after rollover"
        );
    }
}

contract SimpleTimelockIERC1155 is TimelockIERC1155, TimerCheats {
    uint256 public myLockDuration;

    constructor(address _initialOwner, uint256 _lockDuration)
        TimelockIERC1155(_initialOwner)
        TimerCheats(SafeCast.toUint48(block.timestamp))
    {
        myLockDuration = _lockDuration;
    }

    function lockDuration() public view override returns (uint256 lockDuration_) {
        return myLockDuration;
    }

    function currentPeriod() public view override returns (uint256 currentPeriod_) {
        return elapsed24Hours();
    }

    function setCurrentPeriod(uint256 currentPeriod_) public override {
        warp24HourPeriods(SafeCast.toUint48(currentPeriod_));
    }
}
