// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { TimelockAsyncUnlock } from "@credbull/timelock/TimelockAsyncUnlock.sol";
import { ERC1155MintableBurnable } from "@test/test/token/ERC1155/ERC1155MintableBurnable.t.sol";
import { SimpleTimelockAsyncUnlock } from "@test/test/timelock/SimpleTimelockAsyncUnlock.t.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { IERC5679Ext1155 } from "@credbull/token/ERC1155/IERC5679Ext1155.sol";

import { Test } from "forge-std/Test.sol";

contract TimelockAsyncUnlockTest is Test {
    SimpleTimelockAsyncUnlock internal asyncUnlock;
    IERC5679Ext1155 private deposits;

    uint256 private constant NOTICE_PERIOD = 1;

    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");

    uint256[] public lockAmounts;
    uint256[] public depositPeriods;

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

        _lockInMultipleDepositPeriods();
    }

    function test__TimelockAsyncUnlock__LocksInMultipleDepositPeriods() public view {
        for (uint256 i = 0; i < depositPeriods.length; ++i) {
            assertEq(
                lockAmounts[i],
                asyncUnlock.lockedAmount(alice, depositPeriods[i]),
                "lockAmount is not locked in depositPeriod"
            );
        }
    }

    /**
     * S1
     * Scenario: Alice requests unlock for 2 deposit periods
     * Alice unlocks using requestId
     */
    function test__TimelockAsyncUnlock__RequestAndUnlockSucceeds() public {
        uint256 unlockPeriod = asyncUnlock.currentPeriod() + NOTICE_PERIOD;

        // request unlock
        uint256[] memory depositPeriodsForUnlock = new uint256[](2);
        uint256[] memory amountsForUnlock = new uint256[](2);
        depositPeriodsForUnlock[0] = 1;
        depositPeriodsForUnlock[1] = 4;
        amountsForUnlock[0] = 1800;
        amountsForUnlock[1] = 1200;

        vm.prank(alice);
        uint256 requestId = asyncUnlock.requestUnlock(alice, depositPeriodsForUnlock, amountsForUnlock);

        (uint256[] memory actualUnlockDepositPeriods, uint256[] memory actualUnlockAmounts) =
            asyncUnlock.unlockRequests(alice, requestId);

        assertEq(depositPeriodsForUnlock, actualUnlockDepositPeriods, "deposit periods don't match");
        assertEq(amountsForUnlock, actualUnlockAmounts, "amounts don't match");

        // warp to unlock period
        asyncUnlock.setCurrentPeriod(unlockPeriod);

        // now unlock
        vm.prank(alice);
        (uint256[] memory unlockedDepositPeriods, uint256[] memory unlockedAmounts) =
            asyncUnlock.unlock(alice, requestId);

        assertEq(
            unlockedDepositPeriods.length,
            2,
            "unlockedDepositPeriods should be same as depsoitPeriods requested for unlock"
        );
        assertEq(unlockedAmounts.length, 2, "unlockedAmounts should be same as amounts requested for unlock");

        assertEq(
            0,
            asyncUnlock.unlockRequestAmountByDepositPeriod(alice, depositPeriodsForUnlock[0]),
            "unlockRequest should be released(index=0)"
        );
        assertEq(
            lockAmounts[0] - amountsForUnlock[0],
            asyncUnlock.lockedAmount(alice, depositPeriodsForUnlock[0]),
            "deposit lock not released(index=0)"
        );

        assertEq(
            0,
            asyncUnlock.unlockRequestAmountByDepositPeriod(alice, depositPeriodsForUnlock[1]),
            "unlockRequest should be released(index=1)"
        );
        assertEq(
            lockAmounts[1] - amountsForUnlock[1],
            asyncUnlock.lockedAmount(alice, depositPeriodsForUnlock[1]),
            "deposit lock not released(index=1)"
        );

        assertEq(0, asyncUnlock.unlockRequestAmount(alice, requestId), "unlockRequest amount should be 0");
    }

    /**
     * S2
     * Scenario: Alice tries to unlock prior to deposit period
     * and expect it fails
     */
    function test__TimelockAsyncUnlock__UnlockPriorToDepositPeriodFails() public {
        asyncUnlock.setCurrentPeriod(depositPeriods[0]);
        {
            (uint256[] memory depositPeriodsForUnlock, uint256[] memory amountsForUnlock) =
                (_asSingletonArray(8), _asSingletonArray(1800));

            vm.prank(alice);
            uint256 requestId = asyncUnlock.requestUnlock(alice, depositPeriodsForUnlock, amountsForUnlock);

            // move current period to unlock Period
            asyncUnlock.setCurrentPeriod(asyncUnlock.minUnlockPeriod());
            vm.expectRevert(
                abi.encodeWithSelector(
                    TimelockAsyncUnlock.TimelockAsyncUnlock__UnlockBeforeDepositPeriod.selector,
                    alice,
                    alice,
                    depositPeriodsForUnlock[0],
                    requestId
                )
            );
            vm.prank(alice);
            asyncUnlock.unlock(alice, requestId);
        }

        {
            // test when depositPeriodsForUnlock length is bigger than 1
            uint256[] memory depositPeriodsForUnlock = new uint256[](2);
            uint256[] memory amountsForUnlock = new uint256[](2);
            depositPeriodsForUnlock[0] = 1;
            depositPeriodsForUnlock[1] = 4;
            amountsForUnlock[0] = 1800;
            amountsForUnlock[1] = 1200;

            vm.prank(alice);
            uint256 requestId = asyncUnlock.requestUnlock(alice, depositPeriodsForUnlock, amountsForUnlock);

            // move current period to unlock Period
            asyncUnlock.setCurrentPeriod(asyncUnlock.minUnlockPeriod());

            vm.expectRevert(
                abi.encodeWithSelector(
                    TimelockAsyncUnlock.TimelockAsyncUnlock__UnlockBeforeDepositPeriod.selector,
                    alice,
                    alice,
                    depositPeriodsForUnlock[1],
                    requestId
                )
            );
            vm.prank(alice);
            asyncUnlock.unlock(alice, requestId);
        }
    }

    /**
     * S3
     * Scenario: Alice tries to unlock prior to unlock period
     * We expect it to fail; Alice should unlock when current period is same as or later than unlock period
     */
    function test__TimelockAsyncUnlock__UnlockPriorToUnlockPeriodFails() public {
        uint256 depositPeriod = 0;
        uint256 unlockPeriod = asyncUnlock.currentPeriod() + 1;

        vm.expectRevert(
            abi.encodeWithSelector(
                TimelockAsyncUnlock.TimelockAsyncUnlock__UnlockBeforeUnlockPeriod.selector,
                alice,
                alice,
                asyncUnlock.currentPeriod(),
                unlockPeriod
            )
        );
        vm.prank(alice);
        asyncUnlock.unlock(alice, depositPeriod, unlockPeriod, 1);
    }

    /**
     * S4
     * Scenario: Bob requests unlock for Alice's lockedAmount
     * We expect it to fail
     */
    function test__TimelockAsyncUnlock__OnlyDepositorCanRequestUnlock() public {
        (uint256[] memory depositPeriodsForUnlock, uint256[] memory amountsForUnlock) =
            (_asSingletonArray(1), _asSingletonArray(1800));

        vm.expectRevert(
            abi.encodeWithSelector(TimelockAsyncUnlock.TimelockAsyncUnlock__AuthorizeCallerFailed.selector, bob, alice)
        );
        vm.prank(bob);
        asyncUnlock.requestUnlock(alice, depositPeriodsForUnlock, amountsForUnlock);
    }

    /**
     * S5
     * Scenario: Alice locks and requests unlock
     * Bob can unlock Alice's requested unlock amount
     */
    function test__TimelockAsyncUnlock__AnyoneCanUnlock() public {
        (uint256[] memory depositPeriodsForUnlock, uint256[] memory amountsForUnlock) =
            (_asSingletonArray(1), _asSingletonArray(1800));

        vm.prank(alice);
        uint256 requestId = asyncUnlock.requestUnlock(alice, depositPeriodsForUnlock, amountsForUnlock);

        asyncUnlock.setCurrentPeriod(asyncUnlock.minUnlockPeriod());

        vm.prank(bob);
        asyncUnlock.unlock(alice, requestId);

        assertEq(
            lockAmounts[0] - amountsForUnlock[0],
            asyncUnlock.lockedAmount(alice, depositPeriodsForUnlock[0]),
            "lockedAmount should be decreased by the amountsForUnlock"
        );

        assertEq(
            0,
            asyncUnlock.unlockRequestAmountByDepositPeriod(alice, depositPeriodsForUnlock[0]),
            "unlockRequested should return 0 after bob unlocks"
        );
    }

    /**
     * S6
     * Scenario: Alice locks and requests unlock amount bigger than locked amount for specific deposit period
     * We expect it to fail
     */
    function test__TimelockAsyncUnlock__ExceededMaxRequestUnlock() public {
        uint256[] memory depositPeriodsForUnlock = new uint256[](2);
        uint256[] memory amountsForUnlock = new uint256[](2);
        depositPeriodsForUnlock[0] = 1;
        depositPeriodsForUnlock[1] = 4;
        amountsForUnlock[0] = 1800;
        amountsForUnlock[1] = 1200;

        vm.prank(alice);
        asyncUnlock.requestUnlock(alice, depositPeriodsForUnlock, amountsForUnlock);

        asyncUnlock.setCurrentPeriod(asyncUnlock.currentPeriod() + 2);

        (uint256[] memory depositPeriodsForUnlock2, uint256[] memory amountsForUnlock2) =
            (_asSingletonArray(4), _asSingletonArray(500));

        vm.expectRevert(
            abi.encodeWithSelector(
                TimelockAsyncUnlock.TimelockAsyncUnlock__ExceededMaxRequestUnlock.selector,
                alice,
                depositPeriodsForUnlock2[0],
                amountsForUnlock2[0],
                lockAmounts[1] - amountsForUnlock[1]
            )
        );
        vm.prank(alice);
        asyncUnlock.requestUnlock(alice, depositPeriodsForUnlock2, amountsForUnlock2);
    }

    function test__TimelockAsyncUnlock__MultipleRequestsAndUnlocks() public {
        assertEq(
            lockAmounts[0],
            asyncUnlock.maxRequestUnlock(alice, depositPeriods[0]),
            "maxRequestUnlock should be locked amount"
        );

        // first unlock request
        uint256[] memory depositPeriodsForUnlock = new uint256[](2);
        uint256[] memory amountsForUnlock = new uint256[](2);

        depositPeriodsForUnlock[0] = 1;
        depositPeriodsForUnlock[1] = 4;
        amountsForUnlock[0] = 1800;
        amountsForUnlock[1] = 1200;

        vm.prank(alice);
        uint256 requestId = asyncUnlock.requestUnlock(alice, depositPeriodsForUnlock, amountsForUnlock);

        assertEq(
            amountsForUnlock[0],
            asyncUnlock.unlockRequestAmountByDepositPeriod(alice, depositPeriodsForUnlock[0]),
            "unlockRequested should be created (index=0)"
        );

        assertEq(
            amountsForUnlock[1],
            asyncUnlock.unlockRequestAmountByDepositPeriod(alice, depositPeriodsForUnlock[1]),
            "unlockRequested should be created (index=1)"
        );

        assertEq(
            amountsForUnlock[0] + amountsForUnlock[1],
            asyncUnlock.unlockRequestAmount(alice, requestId),
            "unlockRequested by requestId should be created"
        );

        // second unlock request
        uint256[] memory depositPeriodsForUnlock2 = new uint256[](2);
        uint256[] memory amountsForUnlock2 = new uint256[](2);

        depositPeriodsForUnlock2[0] = 4;
        depositPeriodsForUnlock2[1] = 8;
        amountsForUnlock2[0] = 200;
        amountsForUnlock2[1] = 2000;

        vm.prank(alice);
        uint256 requestId2 = asyncUnlock.requestUnlock(alice, depositPeriodsForUnlock2, amountsForUnlock2);

        assertEq(requestId, requestId2, "RequestIds should be same");

        assertEq(
            amountsForUnlock[0],
            asyncUnlock.unlockRequestAmountByDepositPeriod(alice, depositPeriods[0]),
            "unlockRequested should be created after second unlock requests (index=0)"
        );

        assertEq(
            amountsForUnlock[1] + amountsForUnlock2[0],
            asyncUnlock.unlockRequestAmountByDepositPeriod(alice, depositPeriods[1]),
            "unlockRequested should be created after second unlock requests (index=1)"
        );

        assertEq(
            amountsForUnlock2[1],
            asyncUnlock.unlockRequestAmountByDepositPeriod(alice, depositPeriods[2]),
            "unlockRequested should be created after second unlock requests (index=2)"
        );

        assertEq(
            amountsForUnlock[0] + amountsForUnlock[1] + amountsForUnlock2[0] + amountsForUnlock2[1],
            asyncUnlock.unlockRequestAmount(alice, requestId),
            "unlockRequested by requestId should be created after second unlock requests"
        );

        // unlock
        asyncUnlock.setCurrentPeriod(asyncUnlock.minUnlockPeriod());

        vm.prank(alice);
        (uint256[] memory unlockedDepositPeriods, uint256[] memory unlockedAmounts) =
            asyncUnlock.unlock(alice, requestId);

        assertEq(unlockedDepositPeriods.length, 3);

        for (uint256 i = 0; i < unlockedDepositPeriods.length; ++i) {
            assertEq(unlockedDepositPeriods[i], depositPeriods[i]);

            assertEq(0, asyncUnlock.unlockRequestAmountByDepositPeriod(alice, depositPeriods[1]));
        }

        assertEq(amountsForUnlock[0], unlockedAmounts[0], "Unlocked amount should be amount for unlock (index=0)");

        assertEq(
            amountsForUnlock[1] + amountsForUnlock2[0],
            unlockedAmounts[1],
            "Unlocked amount should be amount for unlock (index=1)"
        );

        assertEq(amountsForUnlock2[1], unlockedAmounts[2], "Unlocked amount should be amount for unlock (index=2)");

        assertEq(
            lockAmounts[0] - amountsForUnlock[0],
            asyncUnlock.lockedAmount(alice, depositPeriods[0]),
            "Locked amount should be updated after unlock (index=0)"
        );
        assertEq(
            lockAmounts[1] - amountsForUnlock[1] - amountsForUnlock2[0],
            asyncUnlock.lockedAmount(alice, depositPeriods[1]),
            "Locked amount should be updated after unlock (index=1)"
        );
        assertEq(
            lockAmounts[2] - amountsForUnlock2[1],
            asyncUnlock.lockedAmount(alice, depositPeriods[2]),
            "Locked amount should be updated after unlock (index=2)"
        );
    }

    function _asSingletonArray(uint256 element) internal pure returns (uint256[] memory array) {
        array = new uint256[](1);
        array[0] = element;
    }

    function _lockInMultipleDepositPeriods() private {
        depositPeriods.push(1);
        lockAmounts.push(2000);

        depositPeriods.push(4);
        lockAmounts.push(1500);

        depositPeriods.push(8);
        lockAmounts.push(3200);

        vm.startPrank(alice);
        for (uint256 i = 0; i < depositPeriods.length; ++i) {
            asyncUnlock.lock(alice, depositPeriods[i], lockAmounts[i]);
        }
        vm.stopPrank();

        // Set current period greater than the depositPeriod
        asyncUnlock.setCurrentPeriod(depositPeriods[depositPeriods.length - 1] + 1);
    }
}
