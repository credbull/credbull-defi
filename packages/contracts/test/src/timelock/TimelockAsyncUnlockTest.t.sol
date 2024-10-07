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

        for (uint256 i = 0; i < depositPeriodsForUnlock.length; ++i) {
            assertEq(
                amountsForUnlock[i],
                asyncUnlock.unlockRequested(alice, depositPeriodsForUnlock[i]),
                "unlockRequest should be created"
            );
        }

        // warp to unlock period
        asyncUnlock.setCurrentPeriod(unlockPeriod);

        // now unlock
        vm.prank(alice);
        asyncUnlock.unlock(alice, requestId);

        assertEq(
            0,
            asyncUnlock.unlockRequested(alice, depositPeriodsForUnlock[0]),
            "unlockRequest should be released(index=0)"
        );
        assertEq(
            lockAmounts[0] - amountsForUnlock[0],
            asyncUnlock.lockedAmount(alice, depositPeriodsForUnlock[0]),
            "deposit lock not released(index=0)"
        );

        assertEq(
            0,
            asyncUnlock.unlockRequested(alice, depositPeriodsForUnlock[1]),
            "unlockRequest should be released(index=1)"
        );
        assertEq(
            lockAmounts[1] - amountsForUnlock[1],
            asyncUnlock.lockedAmount(alice, depositPeriodsForUnlock[1]),
            "deposit lock not released(index=1)"
        );
    }

    /**
     * S2
     * Scenario: Alice tries to unlock prior to deposit period
     * and expect it fails
     */
    function test__TimelockAsyncUnlock__UnlockPriorToDepositPeriodFails() public {
        asyncUnlock.setCurrentPeriod(depositPeriods[0]);
        {
            (uint256[] memory depositPeriodsForUnlock, uint256[] memory amountsForUnlock) = _asSingletonArrays(8, 1800);

            vm.prank(alice);
            uint256 requestId = asyncUnlock.requestUnlock(alice, depositPeriodsForUnlock, amountsForUnlock);

            // move current period to unlock Period
            asyncUnlock.setCurrentPeriod(asyncUnlock.minUnlockPeriod());
            vm.prank(alice);
            vm.expectRevert(
                abi.encodeWithSelector(
                    TimelockAsyncUnlock.TimelockAsyncUnlock__UnlockBeforeDepositPeriod.selector,
                    alice,
                    alice,
                    depositPeriodsForUnlock[0],
                    requestId
                )
            );
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

            vm.prank(alice);
            vm.expectRevert(
                abi.encodeWithSelector(
                    TimelockAsyncUnlock.TimelockAsyncUnlock__UnlockBeforeDepositPeriod.selector,
                    alice,
                    alice,
                    depositPeriodsForUnlock[1],
                    requestId
                )
            );
            asyncUnlock.unlock(alice, requestId);
        }
    }

    function _asSingletonArrays(uint256 element1, uint256 element2)
        private
        pure
        returns (uint256[] memory array1, uint256[] memory array2)
    {
        assembly ("memory-safe") {
            // Load the free memory pointer
            array1 := mload(0x40)
            // Set array length to 1
            mstore(array1, 1)
            // Store the single element at the next word after the length (where content starts)
            mstore(add(array1, 0x20), element1)

            // Repeat for next array locating it right after the first array
            array2 := add(array1, 0x40)
            mstore(array2, 1)
            mstore(add(array2, 0x20), element2)

            // Update the free memory pointer by pointing after the second array
            mstore(0x40, add(array2, 0x40))
        }
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
