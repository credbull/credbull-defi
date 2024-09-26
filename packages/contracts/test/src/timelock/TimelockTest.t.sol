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
    ITimelock internal timelock; // Use the ITimelock interface

    address internal owner = makeAddr("owner");
    address internal alice = makeAddr("alice");

    LockUntil internal lockUntilDay1 = LockUntil({ releasePeriod: 1, amount: 101 });
    LockUntil internal lockUntilDay2 = LockUntil({ releasePeriod: 2, amount: 22 });

    uint256 internal initialSupply = 1000000;

    function test__Timelock__Lock() public {
        vm.prank(owner);
        timelock.lock(alice, lockUntilDay1.releasePeriod, lockUntilDay1.amount);

        assertEq(
            lockUntilDay1.amount, timelock.lockedAmount(alice, lockUntilDay1.releasePeriod), "incorrect locked amount"
        );

        // Ensure that the unlocked amount is initially zero before any unlock operation
        assertEq(
            0,
            timelock.maxUnlock(alice, lockUntilDay1.releasePeriod - 1),
            "preview unlock should be zero before lockRelease period"
        );
    }

    function test__Timelock__OnlyOwnerCanLockAndUnlock() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        timelock.lock(alice, lockUntilDay1.releasePeriod, lockUntilDay1.amount);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        timelock.unlock(alice, lockUntilDay1.releasePeriod, lockUntilDay1.amount);
    }

    function test__Timelock__GetAllLocks() public {
        vm.startPrank(owner);
        timelock.lock(alice, lockUntilDay1.releasePeriod, lockUntilDay1.amount);
        timelock.lock(alice, lockUntilDay2.releasePeriod, lockUntilDay2.amount);
        vm.stopPrank();

        // Fetch all locks for Alice
        uint256[] memory lockPeriods = timelock.lockPeriods(alice, 0, lockUntilDay2.releasePeriod);

        // Assert the correct number of locks returned
        assertEq(lockPeriods.length, 2, "incorrect number of lock periods");

        // Assert the details of the first lock
        assertEq(lockPeriods[0], lockUntilDay1.releasePeriod, "incorrect lock period for first lock");
        assertEq(lockPeriods[1], lockUntilDay2.releasePeriod, "incorrect lock period for second lock");
    }

    function test__Timelock__UnlockFailsBeforeTime() public {
        vm.prank(owner);
        timelock.lock(alice, lockUntilDay1.releasePeriod, lockUntilDay1.amount);

        uint256 lockedAmount = timelock.lockedAmount(alice, lockUntilDay1.releasePeriod);
        assertEq(lockedAmount, lockUntilDay1.amount, "incorrect locked amount");

        // attempt to unlock before the release period should fail
        warpToPeriod(timelock, lockUntilDay1.releasePeriod - 1); // warp forward - but to the release period

        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                ITimelock.ITimelock__LockDurationNotExpired.selector, alice, 0, lockUntilDay1.releasePeriod
            )
        );
        timelock.unlock(alice, lockUntilDay1.releasePeriod, lockUntilDay1.amount);
    }

    function test__Timelock__PartialAndFullUnlockAfterTime() public {
        vm.prank(owner);
        timelock.lock(alice, lockUntilDay1.releasePeriod, lockUntilDay1.amount);

        // warp to releasePeriod
        warpToPeriod(timelock, lockUntilDay1.releasePeriod);

        assertEq(
            lockUntilDay1.amount,
            timelock.maxUnlock(alice, lockUntilDay1.releasePeriod),
            "preview unlock should be the full amount"
        );

        // partial unlock
        uint256 partialUnlockAmount = 5;
        vm.prank(owner);
        timelock.unlock(alice, lockUntilDay1.releasePeriod, partialUnlockAmount);

        uint256 remainingLockedAmount = timelock.lockedAmount(alice, lockUntilDay1.releasePeriod);
        assertEq(
            remainingLockedAmount,
            lockUntilDay1.amount - partialUnlockAmount,
            "incorrect remaining locked amount after partial unlock"
        );

        assertEq(
            remainingLockedAmount,
            timelock.maxUnlock(alice, lockUntilDay1.releasePeriod),
            "preview unlock should be the residual amount"
        );

        // full unlock of the remaining amount
        vm.prank(owner);
        timelock.unlock(alice, lockUntilDay1.releasePeriod, remainingLockedAmount);

        assertEq(0, timelock.lockedAmount(alice, lockUntilDay1.releasePeriod), "all tokens should be unlocked");
    }

    function warpToPeriod(ITimelock _timelock, uint256 timePeriod) internal virtual;
}
