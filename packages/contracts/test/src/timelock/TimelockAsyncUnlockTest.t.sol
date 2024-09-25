// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ITimelockOpenEnded } from "@credbull/timelock/ITimelockOpenEnded.sol";
import { TimelockAsyncUnlock } from "@credbull/timelock/TimelockAsyncUnlock.sol";
import { ERC1155MintableBurnable } from "@test/test/interest/ERC1155MintableBurnable.t.sol";
import { SimpleTimelockAsyncUnlock } from "@test/test/timelock/SimpleTimelockAsyncUnlock.t.sol";
import { IERC5679Ext1155 } from "@credbull/interest/IERC5679Ext1155.sol";

import { Deposit } from "@test/src/timelock/TimelockTest.t.sol";
import { Test } from "forge-std/Test.sol";

contract TimelockAsyncUnlockTest is Test {
    SimpleTimelockAsyncUnlock internal asyncUnlock;
    IERC5679Ext1155 private deposits;

    uint256 private constant NOTICE_PERIOD = 1;

    address internal owner = makeAddr("owner");
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");

    Deposit private depositDay1 = Deposit({ depositPeriod: 1, amount: 101 });
    Deposit private depositDay2 = Deposit({ depositPeriod: 2, amount: 202 });
    Deposit private depositDay3 = Deposit({ depositPeriod: 3, amount: 303 });

    function setUp() public {
        deposits = new ERC1155MintableBurnable();
        asyncUnlock = new SimpleTimelockAsyncUnlock(NOTICE_PERIOD, deposits);
    }

    function test__TimelockAsyncUnlock__RequestAndUnlockSucceeds() public {
        vm.prank(alice);
        asyncUnlock.lock(alice, depositDay1.depositPeriod, depositDay1.amount);
        assertEq(depositDay1.amount, asyncUnlock.lockedAmount(alice, depositDay1.depositPeriod), "deposit not locked");

        uint256 unlockPeriod = depositDay1.depositPeriod + NOTICE_PERIOD;

        // request unlock
        vm.prank(alice);
        asyncUnlock.requestUnlock(depositDay1.amount, alice, depositDay1.depositPeriod, unlockPeriod);

        // warp to unlock period
        asyncUnlock.setCurrentPeriod(unlockPeriod);

        // now unlock
        vm.prank(alice);
        asyncUnlock.unlock(depositDay1.amount, alice, depositDay1.depositPeriod, unlockPeriod);

        assertEq(0, asyncUnlock.lockedAmount(alice, depositDay1.depositPeriod), "deposit lock not released");
        assertEq(0, asyncUnlock.DEPOSITS().balanceOf(alice, depositDay1.depositPeriod), "deposits should be redeemed");
    }

    // Scenario S6: User tries to redeem the Principal the same day they request redemption - revert
    // TODO TimeLock: Scenario S5: User tries to redeem the APY the same day they request redemption - revert (// TODO - add check for yield - revert if same day)
    function test__TimelockAsyncUnlock_RequestUnlockSameDayFails() public {
        vm.prank(alice);
        asyncUnlock.lock(alice, depositDay1.depositPeriod, depositDay1.amount);

        // check for the depositPeriod validation
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                TimelockAsyncUnlock.TimelockAsyncUnlock__RequestBeforeDepositWithNoticePeriod.selector,
                alice,
                depositDay1.depositPeriod,
                depositDay1.depositPeriod + NOTICE_PERIOD
            )
        );
        asyncUnlock.requestUnlock(depositDay1.amount, alice, depositDay1.depositPeriod, depositDay1.depositPeriod);
    }

    function test__TimelockAsyncUnlock__UnlockPriorToDepositPeriodFails() public {
        uint256 requestedUnlockPeriod = depositDay1.depositPeriod - 1;

        // fail - unlocking before depositing !
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                TimelockAsyncUnlock.TimelockAsyncUnlock__UnlockBeforeDepositPeriod.selector,
                alice,
                requestedUnlockPeriod,
                depositDay1.depositPeriod
            )
        );
        asyncUnlock.unlock(depositDay1.amount, alice, depositDay1.depositPeriod, requestedUnlockPeriod);
    }

    function test__TimelockAsyncUnlock__RequestUnlockPriorToCurrentPlusNoticePeriodFails() public {
        uint256 currentPeriod = 10;
        uint256 unlockPeriod = currentPeriod - 1;

        asyncUnlock.setCurrentPeriod(currentPeriod);

        // fail - requestUnlock is less than the currentPeriod + NOTICE_PERIOD
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                TimelockAsyncUnlock.TimelockAsyncUnlock__RequestBeforeCurrentWithNoticePeriod.selector,
                alice,
                unlockPeriod,
                currentPeriod + NOTICE_PERIOD
            )
        );
        asyncUnlock.requestUnlock(depositDay1.amount, alice, depositDay2.depositPeriod, unlockPeriod);
    }

    function test__TimelockAsyncUnlock__UnlockPriorToCurrentPeriodFails() public {
        uint256 currentPeriod = 5;
        uint256 unlockPeriod = currentPeriod - 1;

        asyncUnlock.setCurrentPeriod(currentPeriod);

        // fail - unlock is less than the currentPeriod
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                TimelockAsyncUnlock.TimelockAsyncUnlock__UnlockBeforeCurrentPeriod.selector,
                alice,
                unlockPeriod,
                currentPeriod
            )
        );
        asyncUnlock.unlock(depositDay1.amount, alice, depositDay1.depositPeriod, unlockPeriod);
    }

    function test__TimelockAsyncUnlock__UnlockWithoutRequestFails() public {
        uint256 unlockPeriod = depositDay1.depositPeriod + NOTICE_PERIOD;

        // warp to unlock period
        asyncUnlock.setCurrentPeriod(unlockPeriod);

        // fail - no unlock request
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                ITimelockOpenEnded.ITimelockOpenEnded__ExceededMaxUnlock.selector, alice, depositDay1.amount, 0
            )
        );
        asyncUnlock.unlock(depositDay1.amount, alice, depositDay1.depositPeriod, unlockPeriod);
    }

    function test__TimelockAsyncUnlock__OnlyDepositorCanRequestOrUnlock() public {
        vm.prank(alice);
        asyncUnlock.lock(alice, depositDay1.depositPeriod, depositDay1.amount);

        uint256 unlockPeriod = depositDay1.depositPeriod + NOTICE_PERIOD;

        vm.prank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(TimelockAsyncUnlock.TimelockAsyncUnlock__RequesterNotOwner.selector, bob, alice)
        );
        asyncUnlock.requestUnlock(depositDay1.amount, alice, depositDay1.depositPeriod, unlockPeriod);

        // warp to unlock period
        asyncUnlock.setCurrentPeriod(unlockPeriod);

        vm.prank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(TimelockAsyncUnlock.TimelockAsyncUnlock__RequesterNotOwner.selector, bob, alice)
        );
        asyncUnlock.unlock(depositDay1.amount, alice, depositDay1.depositPeriod, unlockPeriod);
    }
}
