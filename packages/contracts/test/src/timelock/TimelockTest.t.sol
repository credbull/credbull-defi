// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ITimelock } from "@test/test/timelock/ITimelock.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { TestParamSet } from "@test/test/token/ERC1155/TestParamSet.t.sol";

import { Test } from "forge-std/Test.sol";

abstract contract TimelockTest is Test {
    using TestParamSet for TestParamSet.TestParam[];

    ITimelock internal _timelock; // Use the ITimelock interface

    address internal _owner = makeAddr("owner");
    address internal _alice = makeAddr("alice");

    // using redeem period as release period.  deposit period is ignored.
    TestParamSet.TestParam internal _param1 =
        TestParamSet.TestParam({ principal: 101, depositPeriod: 0, redeemPeriod: 1 });
    TestParamSet.TestParam internal _param2 =
        TestParamSet.TestParam({ principal: 202, depositPeriod: 0, redeemPeriod: 2 });
    TestParamSet.TestParam internal _param3 =
        TestParamSet.TestParam({ principal: 303, depositPeriod: 0, redeemPeriod: 3 });
    TestParamSet.TestParam internal _param4 =
        TestParamSet.TestParam({ principal: 404, depositPeriod: 0, redeemPeriod: 4 });

    uint256 internal initialSupply = 1000000;

    function test__Timelock__Lock() public {
        vm.prank(_owner);
        _timelock.lock(_alice, _param1.redeemPeriod, _param1.principal);

        assertEq(_param1.principal, _timelock.lockedAmount(_alice, _param1.redeemPeriod), "incorrect locked amount");

        // Ensure that the unlocked amount is initially zero before any unlock operation
        assertEq(
            0,
            _timelock.maxUnlock(_alice, _param1.redeemPeriod - 1),
            "preview unlock should be zero before lockRelease period"
        );
    }

    function test__Timelock__OnlyOwnerCanLockAndUnlock() public {
        vm.prank(_alice);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _alice));
        _timelock.lock(_alice, _param1.redeemPeriod, _param1.principal);

        vm.prank(_alice);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _alice));
        _timelock.unlock(_alice, _param1.redeemPeriod, _param1.principal);

        vm.prank(_alice);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, _alice));
        _timelock.rolloverUnlocked(_alice, _param1.redeemPeriod, _param1.principal);
    }

    function test__Timelock__GetAllLocks() public {
        vm.startPrank(_owner);
        _timelock.lock(_alice, _param1.redeemPeriod, _param1.principal);
        _timelock.lock(_alice, _param2.redeemPeriod, _param2.principal);
        _timelock.lock(_alice, _param3.redeemPeriod, _param3.principal);
        _timelock.lock(_alice, _param4.redeemPeriod, _param4.principal);
        vm.stopPrank();

        // =============== verify all lock periods ===============
        (uint256[] memory expectedLockPeriodsAll, uint256[] memory expectedAmountsAll) = _allParams().redeems();

        (uint256[] memory actualLockPeriods, uint256[] memory actualAmounts) =
            _timelock.lockPeriods(_alice, 0, _param4.redeemPeriod, 1);

        assertEq(expectedLockPeriodsAll, actualLockPeriods, "lock periods don't match");
        assertEq(expectedAmountsAll, actualAmounts, "locked amounts don't match");

        // =============== every other one (the evens) ===============
        (uint256[] memory expectedLockPeriodsEvens, uint256[] memory expectedAmountsEvens) = _evenParams().redeems();

        (uint256[] memory actualLockPeriodsEvens, uint256[] memory actualAmountsEvens) =
            _timelock.lockPeriods(_alice, 0, _param4.redeemPeriod, 2);
        assertEq(expectedLockPeriodsEvens, actualLockPeriodsEvens, "lock periods don't match - evens");
        assertEq(expectedAmountsEvens, actualAmountsEvens, "locked amounts don't match - evens");
    }

    function test__Timelock__UnlockFailsBeforeTime() public {
        vm.prank(_owner);
        _timelock.lock(_alice, _param1.redeemPeriod, _param1.principal);

        uint256 lockedAmount = _timelock.lockedAmount(_alice, _param1.redeemPeriod);
        assertEq(lockedAmount, _param1.principal, "incorrect locked amount");

        // attempt to unlock before the release period should fail
        _warpToPeriod(_timelock, _param1.redeemPeriod - 1); // warp forward - but to the release period

        vm.prank(_owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                ITimelock.ITimelock__LockDurationNotExpired.selector, _alice, 0, _param1.redeemPeriod
            )
        );
        _timelock.unlock(_alice, _param1.redeemPeriod, _param1.principal);
    }

    function test__Timelock__PartialAndFullUnlockAfterTime() public {
        vm.prank(_owner);
        _timelock.lock(_alice, _param1.redeemPeriod, _param1.principal);

        // warp to releasePeriod
        _warpToPeriod(_timelock, _param1.redeemPeriod);

        assertEq(
            _param1.principal,
            _timelock.maxUnlock(_alice, _param1.redeemPeriod),
            "preview unlock should be the full amount"
        );

        // partial unlock
        uint256 partialUnlockAmount = 5;
        vm.prank(_owner);
        _timelock.unlock(_alice, _param1.redeemPeriod, partialUnlockAmount);

        uint256 remainingLockedAmount = _timelock.lockedAmount(_alice, _param1.redeemPeriod);
        assertEq(
            remainingLockedAmount,
            _param1.principal - partialUnlockAmount,
            "incorrect remaining locked amount after partial unlock"
        );

        assertEq(
            remainingLockedAmount,
            _timelock.maxUnlock(_alice, _param1.redeemPeriod),
            "preview unlock should be the residual amount"
        );

        // full unlock of the remaining amount
        vm.prank(_owner);
        _timelock.unlock(_alice, _param1.redeemPeriod, remainingLockedAmount);

        assertEq(0, _timelock.lockedAmount(_alice, _param1.redeemPeriod), "all tokens should be unlocked");
    }

    function test__Timelock__RolloverUnlockedPartial() public virtual {
        vm.prank(_owner);
        _timelock.lock(_alice, _param1.redeemPeriod, _param1.principal);

        // warp to releasePeriod
        _warpToPeriod(_timelock, _param1.redeemPeriod);

        uint256 unlockableAmount = _timelock.maxUnlock(_alice, _param1.redeemPeriod);
        assertEq(unlockableAmount, _param1.principal, "all tokens should be unlockable after the lock period");

        uint256 partialRolloverAmount = _param1.principal - 10;
        uint256 rolloverLockReleasePeriod = _param1.redeemPeriod + _rolloverLockDuration(_timelock);

        // rollover the unlocked tokens
        vm.prank(_owner);
        _timelock.rolloverUnlocked(_alice, _param1.redeemPeriod, partialRolloverAmount);

        // check rolled-over tokens are locked under the new period
        uint256 lockedAmountAfterRollover = _timelock.lockedAmount(_alice, rolloverLockReleasePeriod);
        assertEq(lockedAmountAfterRollover, partialRolloverAmount, "incorrect locked amount after rollover");

        // check remaining tokens in the original period are reduced
        uint256 remainingUnlockableAmount = _timelock.maxUnlock(_alice, _param1.redeemPeriod);
        assertEq(
            remainingUnlockableAmount,
            _param1.principal - partialRolloverAmount,
            "incorrect remaining unlockable amount after rollover"
        );
    }

    function _allParams() public view returns (TestParamSet.TestParam[] memory allParams_) {
        TestParamSet.TestParam[] memory allParams = new TestParamSet.TestParam[](4);
        allParams[0] = _param1;
        allParams[1] = _param2;
        allParams[2] = _param3;
        allParams[3] = _param4;
        return allParams;
    }

    function _evenParams() public view returns (TestParamSet.TestParam[] memory evenParams_) {
        TestParamSet.TestParam[] memory evenParams = new TestParamSet.TestParam[](2);
        evenParams[0] = _param2;
        evenParams[1] = _param4;
        return evenParams;
    }

    function _rolloverLockDuration(ITimelock /* timelock_ */ ) internal virtual returns (uint256 lockDuration);

    function _warpToPeriod(ITimelock timelock_, uint256 timePeriod) internal virtual;
}
