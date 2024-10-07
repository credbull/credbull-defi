// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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
        assertEq(0, asyncUnlock._deposits().balanceOf(alice, depositDay1.depositPeriod), "deposits should be redeemed");
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

    /**
     * S4
     * Scenario: Alice requests unlock multiple times
     * Alice unlocks multiple times
     */
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
        assertEq(totalDeposits, asyncUnlock.maxRequestUnlock(alice, depositPeriod), "maxRequestUnlock should be total");

        // request unlock at exactly depositPeriod + noticePeriod
        uint256 unlockPeriod1 = depositPeriod + NOTICE_PERIOD;
        uint256 partialUnlockAmount1 = 10;
        asyncUnlock.setCurrentPeriod(depositPeriod);
        vm.prank(alice);
        asyncUnlock.requestUnlock(alice, depositPeriod, partialUnlockAmount1);

        assertEq(
            partialUnlockAmount1,
            asyncUnlock.unlockRequested(alice, depositPeriod),
            "unlockRequest should have partial amount 1"
        );
        assertEq(totalDeposits, asyncUnlock.lockedAmount(alice, depositPeriod), "deposit not locked");
        assertEq(
            totalDeposits - partialUnlockAmount1,
            asyncUnlock.maxRequestUnlock(alice, depositPeriod),
            "maxRequestUnlock incorrect - unlockPeriod1"
        );

        // request to unlock another partial amount
        uint256 partialUnlockAmount2 = 30;
        vm.prank(alice);
        asyncUnlock.requestUnlock(alice, depositPeriod, partialUnlockAmount2);
        assertEq(
            partialUnlockAmount1 + partialUnlockAmount2,
            asyncUnlock.unlockRequested(alice, depositPeriod),
            "unlockRequest should have sum of 2 partial amounts"
        );

        // now create a request for a different unlockPeriod
        uint256 unlockPeriod2 = depositPeriod + 5 + NOTICE_PERIOD;
        asyncUnlock.setCurrentPeriod(depositPeriod + 5);

        assertEq(
            totalDeposits - partialUnlockAmount1 - partialUnlockAmount2,
            asyncUnlock.maxRequestUnlock(alice, depositPeriod),
            "maxRequestUnlock incorrect in second unlockPeriod"
        );
        vm.prank(alice);
        asyncUnlock.requestUnlock(alice, depositPeriod, totalDeposits - partialUnlockAmount1 - partialUnlockAmount2);
        assertEq(
            totalDeposits, asyncUnlock.unlockRequested(alice, depositPeriod), "unlockRequest should have total amount"
        );

        // now unlock
        asyncUnlock.setCurrentPeriod(unlockPeriod1);
        vm.prank(alice);
        asyncUnlock.unlock(alice, depositPeriod, unlockPeriod1, partialUnlockAmount1);

        assertEq(
            totalDeposits - partialUnlockAmount1,
            asyncUnlock.unlockRequested(alice, depositPeriod),
            "unlockRequested should exclude partialUnlockAmount1"
        );

        assertEq(
            partialUnlockAmount2,
            asyncUnlock.unlockRequested(alice, depositPeriod, unlockPeriod1),
            "unlockRequested for unlockPeriod1 should return partialUnlockAmount2"
        );

        assertEq(
            totalDeposits - partialUnlockAmount1,
            asyncUnlock.lockedAmount(alice, depositPeriod),
            "lockedAmount should exclude partialUnlockAmount1"
        );

        vm.prank(alice);
        asyncUnlock.unlock(alice, depositPeriod, unlockPeriod1, partialUnlockAmount2);

        assertEq(
            totalDeposits - partialUnlockAmount1 - partialUnlockAmount2,
            asyncUnlock.unlockRequested(alice, depositPeriod),
            "unlockRequested should exclude partialUnlockAmount1+partialUnlockAmount2"
        );

        assertEq(
            0,
            asyncUnlock.unlockRequested(alice, depositPeriod, unlockPeriod1),
            "unlockRequested for unlockPeriod1 should return 0 after 2 unlocks"
        );

        assertEq(
            totalDeposits - partialUnlockAmount1 - partialUnlockAmount2,
            asyncUnlock.lockedAmount(alice, depositPeriod),
            "lockedAmount should exclude partialUnlockAmount1+partialUnlockAmount2"
        );

        asyncUnlock.setCurrentPeriod(unlockPeriod2);
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                TimelockAsyncUnlock.TimelockAsyncUnlock__ExceededMaxUnlock.selector,
                alice,
                totalDeposits - partialUnlockAmount1 - partialUnlockAmount2 + 1,
                totalDeposits - partialUnlockAmount1 - partialUnlockAmount2
            )
        );
        asyncUnlock.unlock(
            alice, depositPeriod, unlockPeriod2, totalDeposits - partialUnlockAmount1 - partialUnlockAmount2 + 1
        );

        vm.prank(alice);
        asyncUnlock.unlock(
            alice, depositPeriod, unlockPeriod2, totalDeposits - partialUnlockAmount1 - partialUnlockAmount2
        );

        assertEq(
            0,
            asyncUnlock.unlockRequested(alice, depositPeriod),
            "unlockRequested should return 0 after unlock in unlockPeriod2"
        );

        assertEq(
            0,
            asyncUnlock.unlockRequested(alice, depositPeriod, unlockPeriod2),
            "unlockRequested by unlockPeriod2 should return 0 after unlock in unlockPeriod2"
        );

        assertEq(0, asyncUnlock.lockedAmount(alice, depositPeriod), "lockedAmount should return 0 after all unlocks");
    }

    /**
     * S5
     * Scenario: Bob requests unlock for Alice's lockedAmount
     * We expect it to fail
     */
    function test__TimelockAsyncUnlock__OnlyDepositorCanRequestUnlock() public {
        vm.prank(alice);
        asyncUnlock.lock(alice, depositDay1.depositPeriod, depositDay1.amount);

        vm.prank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(TimelockAsyncUnlock.TimelockAsyncUnlock__AuthorizeCallerFailed.selector, bob, alice)
        );
        asyncUnlock.requestUnlock(alice, depositDay1.depositPeriod, depositDay1.amount);
    }

    /**
     * S6
     * Scenario: Alice locks and requests unlock
     * Bob can unlock Alice's requested unlock amount
     */
    function test__TimelockAsyncUnlock__AnyoneCanUnlock() public {
        vm.prank(alice);
        asyncUnlock.lock(alice, depositDay1.depositPeriod, depositDay1.amount);

        asyncUnlock.setCurrentPeriod(depositDay1.depositPeriod);

        vm.prank(alice);
        asyncUnlock.requestUnlock(alice, depositDay1.depositPeriod, depositDay1.amount);

        uint256 unlockPeriod = depositDay1.depositPeriod + NOTICE_PERIOD;

        asyncUnlock.setCurrentPeriod(unlockPeriod);

        vm.prank(bob);
        asyncUnlock.unlock(alice, depositDay1.depositPeriod, unlockPeriod, depositDay1.amount);

        assertEq(
            0,
            asyncUnlock.lockedAmount(alice, depositDay1.depositPeriod),
            "lockedAmount should return 0 after bob unlocks"
        );

        assertEq(
            0,
            asyncUnlock.unlockRequested(alice, depositDay1.depositPeriod),
            "unlockRequested should return 0 after bob unlocks"
        );
    }

    /**
     * S7
     * Scenario: Alice locks and requests unlock amount
     * Alice tries to unlock the amount which is bigger than one he requests
     * We expect it to fail
     */
    function test__TimelockAsyncUnlock__ExceededMaxUnlock() public {
        vm.prank(alice);
        asyncUnlock.lock(alice, depositDay1.depositPeriod, depositDay1.amount);

        asyncUnlock.setCurrentPeriod(depositDay1.depositPeriod);

        vm.prank(alice);
        asyncUnlock.requestUnlock(alice, depositDay1.depositPeriod, depositDay1.amount);

        uint256 unlockAmount = depositDay1.amount + 10;
        uint256 unlockPeriod = depositDay1.depositPeriod + NOTICE_PERIOD;

        asyncUnlock.setCurrentPeriod(unlockPeriod);
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                TimelockAsyncUnlock.TimelockAsyncUnlock__ExceededMaxUnlock.selector,
                alice,
                unlockAmount,
                depositDay1.amount
            )
        );
        asyncUnlock.unlock(alice, depositDay1.depositPeriod, unlockPeriod, unlockAmount);
    }

    /**
     * S8
     * Scenario: Alice locks and requests unlock amount bigger than locked amount
     * We expect it to fail
     */
    function test__TimelockAsyncUnlock__ExceededMaxRequestUnlock() public {
        vm.prank(alice);
        asyncUnlock.lock(alice, depositDay1.depositPeriod, depositDay1.amount);

        asyncUnlock.setCurrentPeriod(depositDay1.depositPeriod);

        uint256 requestUnlockAmount = depositDay1.amount + 10;

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                TimelockAsyncUnlock.TimelockAsyncUnlock__ExceededMaxRequestUnlock.selector,
                alice,
                requestUnlockAmount,
                depositDay1.amount
            )
        );
        asyncUnlock.requestUnlock(alice, depositDay1.depositPeriod, requestUnlockAmount);
    }
}
