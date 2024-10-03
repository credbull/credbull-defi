// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ITimelockOpenEnded } from "@credbull/timelock/ITimelockOpenEnded.sol";
import { TimelockAsyncUnlock } from "@credbull/timelock/TimelockAsyncUnlock.sol";
import { ERC1155MintableBurnable } from "@test/test/token/ERC1155/ERC1155MintableBurnable.t.sol";
import { SimpleTimelockAsyncUnlock } from "@test/test/timelock/SimpleTimelockAsyncUnlock.t.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { IERC5679Ext1155 } from "@credbull/token/ERC1155/IERC5679Ext1155.sol";

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
        asyncUnlock = new SimpleTimelockAsyncUnlock();
        asyncUnlock = SimpleTimelockAsyncUnlock(
            address(
                new ERC1967Proxy(
                    address(asyncUnlock),
                    abi.encodeWithSelector(asyncUnlock.initialize.selector, NOTICE_PERIOD, deposits)
                )
            )
        );
    }

    function test__TimelockAsyncUnlock__RequestAndUnlockSucceeds() public {
        vm.prank(alice);
        asyncUnlock.lock(alice, depositDay1.depositPeriod, depositDay1.amount);
        assertEq(depositDay1.amount, asyncUnlock.lockedAmount(alice, depositDay1.depositPeriod), "deposit not locked");

        uint256 unlockPeriod = depositDay1.depositPeriod + NOTICE_PERIOD;

        // request unlock
        vm.prank(alice);
        asyncUnlock.requestUnlock(alice, depositDay1.depositPeriod, unlockPeriod, depositDay1.amount);
        assertEq(
            depositDay1.amount,
            asyncUnlock.unlockRequested(alice, depositDay1.depositPeriod).amount,
            "unlockRequest should be created"
        );

        // warp to unlock period
        asyncUnlock.setCurrentPeriod(unlockPeriod);

        // now unlock
        vm.prank(alice);
        asyncUnlock.unlock(alice, depositDay1.depositPeriod, unlockPeriod, depositDay1.amount);

        assertEq(
            0, asyncUnlock.unlockRequested(alice, depositDay1.depositPeriod).amount, "unlockRequest should be released"
        );
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
        asyncUnlock.requestUnlock(alice, depositDay1.depositPeriod, depositDay1.depositPeriod, depositDay1.amount);
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
        asyncUnlock.unlock(alice, depositDay1.depositPeriod, requestedUnlockPeriod, depositDay1.amount);
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
        asyncUnlock.requestUnlock(alice, depositDay2.depositPeriod, unlockPeriod, depositDay1.amount);
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
        asyncUnlock.unlock(alice, depositDay1.depositPeriod, unlockPeriod, depositDay1.amount);
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
        asyncUnlock.unlock(alice, depositDay1.depositPeriod, unlockPeriod, depositDay1.amount);
    }

    function test__TimelockAsyncUnlock__MismatchOnUnlockPeriodFails() public {
        vm.prank(alice);
        asyncUnlock.lock(alice, depositDay1.depositPeriod, depositDay1.amount);
        assertEq(depositDay1.amount, asyncUnlock.lockedAmount(alice, depositDay1.depositPeriod), "deposit not locked");

        uint256 unlockPeriod = depositDay1.depositPeriod + NOTICE_PERIOD;

        // request unlock
        vm.prank(alice);
        asyncUnlock.requestUnlock(alice, depositDay1.depositPeriod, unlockPeriod, depositDay1.amount);
        assertEq(
            depositDay1.amount,
            asyncUnlock.unlockRequested(alice, depositDay1.depositPeriod).amount,
            "unlockRequest should be created"
        );

        // warp to unlock period
        asyncUnlock.setCurrentPeriod(unlockPeriod);

        uint256 wrongUnlockPeriod = unlockPeriod + 1;

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                TimelockAsyncUnlock.TimelockAsyncUnlock__UnlockPeriodMismatch.selector,
                alice,
                wrongUnlockPeriod,
                unlockPeriod
            )
        );
        asyncUnlock.unlock(alice, depositDay1.depositPeriod, wrongUnlockPeriod, depositDay1.amount);
    }

    function test__TimelockAsyncUnlock__OnlyDepositorCanRequestOrUnlock() public {
        vm.prank(alice);
        asyncUnlock.lock(alice, depositDay1.depositPeriod, depositDay1.amount);

        uint256 unlockPeriod = depositDay1.depositPeriod + NOTICE_PERIOD;

        vm.prank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(TimelockAsyncUnlock.TimelockAsyncUnlock__RequesterNotOwner.selector, bob, alice)
        );
        asyncUnlock.requestUnlock(alice, depositDay1.depositPeriod, unlockPeriod, depositDay1.amount);

        // warp to unlock period
        asyncUnlock.setCurrentPeriod(unlockPeriod);

        vm.prank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(TimelockAsyncUnlock.TimelockAsyncUnlock__RequesterNotOwner.selector, bob, alice)
        );
        asyncUnlock.unlock(alice, depositDay1.depositPeriod, unlockPeriod, depositDay1.amount);
    }

    function test__TimelockAsyncUnlock__MultipleRequestsAndUnlocks() public {
        uint256 depositPeriod = 11;
        uint256 depositAmount1 = 34;
        uint256 depositAmount2 = 56;

        vm.startPrank(alice);
        asyncUnlock.lock(alice, depositPeriod, depositAmount1);
        asyncUnlock.lock(alice, depositPeriod, depositAmount2);
        vm.stopPrank();

        uint256 totalDeposits = depositAmount1 + depositAmount2;
        assertEq(totalDeposits, asyncUnlock.lockedAmount(alice, depositPeriod), "deposit not locked");
        assertEq(0, asyncUnlock.unlockedAmount(alice, depositPeriod), "nothing should be unlocked");
        assertEq(totalDeposits, asyncUnlock.maxRequestUnlock(alice, depositPeriod), "maxRequestUnlock should be total");
        assertEq(totalDeposits, asyncUnlock.maxUnlock(alice, depositPeriod), "maxUnlock should be total");

        // request unlock at exactly depositPeriod + noticePeriod
        uint256 unlockPeriod1 = depositPeriod + NOTICE_PERIOD;
        uint256 partialUnlockAmount1 = 10;
        vm.prank(alice);
        asyncUnlock.requestUnlock(alice, depositPeriod, unlockPeriod1, partialUnlockAmount1);
        assertEq(
            unlockPeriod1,
            asyncUnlock.unlockRequested(alice, depositPeriod).unlockPeriod,
            "unlockRequest should have unlock request period 1"
        );
        assertEq(
            partialUnlockAmount1,
            asyncUnlock.unlockRequested(alice, depositPeriod).amount,
            "unlockRequest should have partial amount 1"
        );
        assertEq(totalDeposits, asyncUnlock.lockedAmount(alice, depositPeriod), "deposit not locked");
        assertEq(0, asyncUnlock.unlockedAmount(alice, depositPeriod), "nothing should be unlocked");
        assertEq(
            totalDeposits - partialUnlockAmount1,
            asyncUnlock.maxRequestUnlock(alice, depositPeriod),
            "maxRequestUnlock incorrect - unlockPeriod1"
        );
        assertEq(totalDeposits, asyncUnlock.maxUnlock(alice, depositPeriod), "maxUnlock should be total");

        // request to unlock the remainder
        vm.prank(alice);
        asyncUnlock.requestUnlock(alice, depositPeriod, unlockPeriod1, totalDeposits - partialUnlockAmount1);
        assertEq(
            totalDeposits,
            asyncUnlock.unlockRequested(alice, depositPeriod).amount,
            "unlockRequest should have total amount"
        );

        // now create a request for a different unlockPeriod - "resets" the unlock request to this amount
        uint256 unlockPeriod2 = depositPeriod + NOTICE_PERIOD + 1;
        uint256 partialUnlockAmount2 = 20;
        vm.prank(alice);
        asyncUnlock.requestUnlock(alice, depositPeriod, unlockPeriod2, partialUnlockAmount2);
        assertEq(
            unlockPeriod2,
            asyncUnlock.unlockRequested(alice, depositPeriod).unlockPeriod,
            "unlockRequest should have unlock request period 2"
        );
        assertEq(
            partialUnlockAmount2,
            asyncUnlock.unlockRequested(alice, depositPeriod).amount,
            "unlockRequest should have partial amount 2"
        );
        assertEq(totalDeposits, asyncUnlock.lockedAmount(alice, depositPeriod), "deposit not locked");
        assertEq(0, asyncUnlock.unlockedAmount(alice, depositPeriod), "nothing should be unlocked");
        assertEq(
            totalDeposits - partialUnlockAmount2,
            asyncUnlock.maxRequestUnlock(alice, depositPeriod),
            "maxRequestUnlock incorrect - unlockPeriod2"
        );
        assertEq(totalDeposits, asyncUnlock.maxUnlock(alice, depositPeriod), "maxUnlock should be total");

        // now unlock
        vm.prank(alice);
        asyncUnlock.unlock(alice, depositPeriod, unlockPeriod2, partialUnlockAmount2);

        assertEq(0, asyncUnlock.unlockRequested(alice, depositPeriod).amount, "unlockRequest should be released");
        assertEq(
            totalDeposits - partialUnlockAmount2,
            asyncUnlock.lockedAmount(alice, depositPeriod),
            "deposit lock not released"
        );
        assertEq(0, asyncUnlock.unlockedAmount(alice, depositPeriod), "nothing should be unlocked"); // there's no unlocked state per-se
        assertEq(
            totalDeposits - partialUnlockAmount2,
            asyncUnlock.maxRequestUnlock(alice, depositPeriod),
            "maxRequestUnlock incorrect residual"
        );
        assertEq(
            totalDeposits - partialUnlockAmount2,
            asyncUnlock.maxUnlock(alice, depositPeriod),
            "maxUnlock should be residual"
        );
    }
}
