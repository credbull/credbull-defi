// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ITimelock } from "@credbull/timelock/ITimelock.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { Test } from "forge-std/Test.sol";

struct Deposit {
    uint256 depositPeriod;
    uint256 amount;
}

struct LockUntil {
    uint256 releasePeriod;
    uint256 amount;
}

abstract contract TimelockTest is Test {
    ITimelock internal _timelock; // Use the ITimelock interface

    address internal _owner = makeAddr("owner");
    address internal _alice = makeAddr("alice");

    LockUntil internal _lockUntilDay1 = LockUntil({ releasePeriod: 1, amount: 101 });
    LockUntil internal _lockUntilDay2 = LockUntil({ releasePeriod: 2, amount: 22 });

    uint256 internal initialSupply = 1000000;

    function test__Timelock__Lock() public {
        vm.prank(_owner);
        _timelock.lock(_alice, _lockUntilDay1.releasePeriod, _lockUntilDay1.amount);

        assertEq(
            _lockUntilDay1.amount,
            _timelock.lockedAmount(_alice, _lockUntilDay1.releasePeriod),
            "incorrect locked amount"
        );

        // Ensure that the unlocked amount is initially zero before any unlock operation
        assertEq(
            0,
            _timelock.maxUnlock(_alice, _lockUntilDay1.releasePeriod - 1),
            "preview unlock should be zero before lockRelease period"
        );
    }

    function test__Timelock__OnlyOwnerCanLockAndUnlock() public {
        vm.prank(_alice);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _alice));
        _timelock.lock(_alice, _lockUntilDay1.releasePeriod, _lockUntilDay1.amount);

        vm.prank(_alice);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _alice));
        _timelock.unlock(_alice, _lockUntilDay1.releasePeriod, _lockUntilDay1.amount);

        vm.prank(_alice);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _alice));
        _timelock.rolloverUnlocked(_alice, _lockUntilDay1.releasePeriod, _lockUntilDay1.amount);
    }

    function test__Timelock__GetAllLocks() public {
        vm.startPrank(_owner);
        _timelock.lock(_alice, _lockUntilDay1.releasePeriod, _lockUntilDay1.amount);
        _timelock.lock(_alice, _lockUntilDay2.releasePeriod, _lockUntilDay2.amount);
        vm.stopPrank();

        // Fetch all locks for Alice
        uint256[] memory lockPeriods = _timelock.lockPeriods(_alice, 0, _lockUntilDay2.releasePeriod);

        // Assert the correct number of locks returned
        assertEq(lockPeriods.length, 2, "incorrect number of lock periods");

        // Assert the details of the first lock
        assertEq(lockPeriods[0], _lockUntilDay1.releasePeriod, "incorrect lock period for first lock");
        assertEq(lockPeriods[1], _lockUntilDay2.releasePeriod, "incorrect lock period for second lock");
    }

    function test__Timelock__UnlockFailsBeforeTime() public {
        vm.prank(_owner);
        _timelock.lock(_alice, _lockUntilDay1.releasePeriod, _lockUntilDay1.amount);

        uint256 lockedAmount = _timelock.lockedAmount(_alice, _lockUntilDay1.releasePeriod);
        assertEq(lockedAmount, _lockUntilDay1.amount, "incorrect locked amount");

        // attempt to unlock before the release period should fail
        warpToPeriod(_timelock, _lockUntilDay1.releasePeriod - 1); // warp forward - but to the release period

        vm.prank(_owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                ITimelock.ITimelock__LockDurationNotExpired.selector, _alice, 0, _lockUntilDay1.releasePeriod
            )
        );
        _timelock.unlock(_alice, _lockUntilDay1.releasePeriod, _lockUntilDay1.amount);
    }

    function test__Timelock__PartialAndFullUnlockAfterTime() public {
        vm.prank(_owner);
        _timelock.lock(_alice, _lockUntilDay1.releasePeriod, _lockUntilDay1.amount);

        // warp to releasePeriod
        warpToPeriod(_timelock, _lockUntilDay1.releasePeriod);

        assertEq(
            _lockUntilDay1.amount,
            _timelock.maxUnlock(_alice, _lockUntilDay1.releasePeriod),
            "preview unlock should be the full amount"
        );

        // partial unlock
        uint256 partialUnlockAmount = 5;
        vm.prank(_owner);
        _timelock.unlock(_alice, _lockUntilDay1.releasePeriod, partialUnlockAmount);

        uint256 remainingLockedAmount = _timelock.lockedAmount(_alice, _lockUntilDay1.releasePeriod);
        assertEq(
            remainingLockedAmount,
            _lockUntilDay1.amount - partialUnlockAmount,
            "incorrect remaining locked amount after partial unlock"
        );

        assertEq(
            remainingLockedAmount,
            _timelock.maxUnlock(_alice, _lockUntilDay1.releasePeriod),
            "preview unlock should be the residual amount"
        );

        // full unlock of the remaining amount
        vm.prank(_owner);
        _timelock.unlock(_alice, _lockUntilDay1.releasePeriod, remainingLockedAmount);

        assertEq(0, _timelock.lockedAmount(_alice, _lockUntilDay1.releasePeriod), "all tokens should be unlocked");
    }

    function test__Timelock__RolloverUnlockedPartial() public virtual {
        vm.prank(_owner);
        _timelock.lock(_alice, _lockUntilDay1.releasePeriod, _lockUntilDay1.amount);

        // warp to releasePeriod
        warpToPeriod(_timelock, _lockUntilDay1.releasePeriod);

        uint256 unlockableAmount = _timelock.maxUnlock(_alice, _lockUntilDay1.releasePeriod);
        assertEq(unlockableAmount, _lockUntilDay1.amount, "all tokens should be unlockable after the lock period");

        // rollover the unlocked tokens
        vm.prank(_owner);
        _timelock.rolloverUnlocked(_alice, _lockUntilDay1.releasePeriod, _lockUntilDay2.amount);

        // check rolled-over tokens are locked under the new period
        uint256 lockedAmountAfterRollover = _timelock.lockedAmount(_alice, _lockUntilDay2.releasePeriod);
        assertEq(lockedAmountAfterRollover, _lockUntilDay2.amount, "incorrect locked amount after rollover");

        // check remaining tokens in the original period are reduced
        uint256 remainingUnlockableAmount = _timelock.maxUnlock(_alice, _lockUntilDay1.releasePeriod);
        assertEq(
            remainingUnlockableAmount,
            _lockUntilDay1.amount - _lockUntilDay2.amount,
            "incorrect remaining unlockable amount after rollover"
        );
    }

    function warpToPeriod(ITimelock timelock_, uint256 timePeriod) internal virtual;
}
