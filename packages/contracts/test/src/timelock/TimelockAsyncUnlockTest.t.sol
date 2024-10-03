// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { TimelockAsyncUnlock } from "@credbull/timelock/TimelockAsyncUnlock.sol";
import { ERC1155MintableBurnable } from "@test/test/token/ERC1155/ERC1155MintableBurnable.t.sol";
import { SimpleTimelockAsyncUnlock } from "@test/test/timelock/SimpleTimelockAsyncUnlock.t.sol";
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
        asyncUnlock = new SimpleTimelockAsyncUnlock(NOTICE_PERIOD, deposits);
    }

    /**
     * S1
     * Scenario: Alice locks [amount]
     * Alice requests unlock for [amount]
     * Alice unlocks [amount] at unlockPeriod
     */
    function test__TimelockAsyncUnlock__RequestAndUnlockSucceeds() public {
        vm.prank(alice);
        asyncUnlock.lock(alice, depositDay1.depositPeriod, depositDay1.amount);
        assertEq(depositDay1.amount, asyncUnlock.lockedAmount(alice, depositDay1.depositPeriod), "deposit not locked");

        uint256 unlockPeriod = asyncUnlock.currentPeriod() + NOTICE_PERIOD;

        // request unlock
        vm.prank(alice);
        asyncUnlock.requestUnlock(alice, depositDay1.depositPeriod, depositDay1.amount);

        assertEq(
            depositDay1.amount,
            asyncUnlock.unlockRequested(alice, depositDay1.depositPeriod),
            "unlockRequest should be created"
        );

        // warp to unlock period
        asyncUnlock.setCurrentPeriod(unlockPeriod);

        // now unlock
        vm.prank(alice);
        asyncUnlock.unlock(alice, depositDay1.depositPeriod, unlockPeriod, depositDay1.amount);

        assertEq(0, asyncUnlock.unlockRequested(alice, depositDay1.depositPeriod), "unlockRequest should be released");
        assertEq(0, asyncUnlock.lockedAmount(alice, depositDay1.depositPeriod), "deposit lock not released");
        assertEq(0, asyncUnlock.DEPOSITS().balanceOf(alice, depositDay1.depositPeriod), "deposits should be redeemed");
    }

    /**
     * S2
     * Scenario: Alice tries to unlock prior to deposit period
     * and expect it fails
     */
    function test__TimelockAsyncUnlock__UnlockPriorToDepositPeriodFails() public {
        uint256 requestedUnlockPeriod = depositDay1.depositPeriod - 1;

        vm.prank(alice);

        vm.expectRevert(
            abi.encodeWithSelector(
                TimelockAsyncUnlock.TimelockAsyncUnlock__UnlockBeforeDepositPeriod.selector,
                alice,
                alice,
                depositDay1.depositPeriod,
                requestedUnlockPeriod
            )
        );

        asyncUnlock.unlock(alice, depositDay1.depositPeriod, requestedUnlockPeriod, depositDay1.amount);
    }

    /**
     * S3
     * Scenario: Alice tries to unlock prior to unlock period
     * We expect it to fail; Alice should unlock when current period is same as or later than unlock period
     */
    function test__TimelockAsyncUnlock__UnlockPriorToUnlockPeriodFails() public {
        uint256 currentPeriod = 5;
        uint256 unlockPeriod = currentPeriod + 1;

        asyncUnlock.setCurrentPeriod(currentPeriod);

        vm.prank(alice);

        vm.expectRevert(
            abi.encodeWithSelector(
                TimelockAsyncUnlock.TimelockAsyncUnlock__UnlockBeforeUnlockPeriod.selector,
                alice,
                alice,
                currentPeriod,
                unlockPeriod
            )
        );

        asyncUnlock.unlock(alice, depositDay1.depositPeriod, unlockPeriod, depositDay1.amount);
    }
}
