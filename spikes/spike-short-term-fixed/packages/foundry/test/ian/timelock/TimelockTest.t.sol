// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ITimelock } from "@credbull-spike/contracts/ian/interfaces/ITimelock.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { Test } from "forge-std/Test.sol";

abstract contract TimelockTest is Test {
  ITimelock internal timelock; // Use the ITimelock interface

  address internal owner = makeAddr("owner");
  address internal alice = makeAddr("alice");
  uint256 internal lockReleasePeriod = 1; // The period until which the tokens are locked
  uint256 internal rolloverPeriod = 2; // The new period for the rollover

  uint256 internal initialSupply = 1000000;

  function test__Timelock__Lock() public {
    uint256 depositAmount = 1000;

    // Alice locks the tokens using the Timelock contract
    vm.startPrank(owner);
    timelock.lock(alice, lockReleasePeriod, depositAmount);
    vm.stopPrank();

    assertEq(depositAmount, timelock.getLockedAmount(alice, lockReleasePeriod), "Incorrect locked amount");

    // Ensure that the unlocked amount is initially zero before any unlock operation
    assertEq(
      0, timelock.previewUnlock(alice, lockReleasePeriod - 1), "preview unlock should be zero before lockRelease period"
    );
  }

  function test__Timelock__OnlyOwnerCanLockAndUnlock() public {
    uint256 depositAmount = 1000;

    vm.startPrank(alice);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
    timelock.lock(alice, lockReleasePeriod, depositAmount);
    vm.stopPrank();

    vm.startPrank(alice);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
    timelock.unlock(alice, lockReleasePeriod, depositAmount);
    vm.stopPrank();
  }

  function test__Timelock__UnlockFailsBeforeTime() public {
    uint256 depositAmount = 1000;

    // Alice locks the tokens using the Timelock contract
    vm.startPrank(owner);
    timelock.lock(alice, lockReleasePeriod, depositAmount);
    vm.stopPrank();

    uint256 lockedAmount = timelock.getLockedAmount(alice, lockReleasePeriod);
    assertEq(lockedAmount, depositAmount, "Incorrect locked amount");

    // Attempt to unlock before the release period should fail
    vm.startPrank(owner);
    vm.expectRevert(abi.encodeWithSelector(ITimelock.LockDurationNotExpired.selector, alice, 0, lockReleasePeriod));
    timelock.unlock(alice, lockReleasePeriod, depositAmount);
    vm.stopPrank();
  }

  function test__Timelock__PartialAndFullUnlockAfterTime() public {
    uint256 depositAmount = 1000;
    uint256 partialUnlockAmount = 400;

    // Alice locks the tokens using the Timelock contract
    vm.startPrank(owner);
    timelock.lock(alice, lockReleasePeriod, depositAmount);
    vm.stopPrank();

    warpToPeriod(timelock, lockReleasePeriod);

    assertEq(
      depositAmount, timelock.previewUnlock(alice, lockReleasePeriod), "preview unlock should be the full amount"
    );

    // Partial unlock
    vm.startPrank(owner);
    timelock.unlock(alice, lockReleasePeriod, partialUnlockAmount);
    vm.stopPrank();

    uint256 remainingLockedAmount = timelock.getLockedAmount(alice, lockReleasePeriod);
    assertEq(
      remainingLockedAmount,
      depositAmount - partialUnlockAmount,
      "Incorrect remaining locked amount after partial unlock"
    );

    assertEq(
      remainingLockedAmount,
      timelock.previewUnlock(alice, lockReleasePeriod),
      "preview unlock should be the residual amount"
    );

    // Full unlock of the remaining amount
    vm.startPrank(owner);
    timelock.unlock(alice, lockReleasePeriod, remainingLockedAmount);
    vm.stopPrank();

    uint256 finalLockedAmount = timelock.getLockedAmount(alice, lockReleasePeriod);
    assertEq(finalLockedAmount, 0, "All tokens should be unlocked");
  }

  function warpToPeriod(ITimelock _timelock, uint256 timePeriod) internal virtual;
}
