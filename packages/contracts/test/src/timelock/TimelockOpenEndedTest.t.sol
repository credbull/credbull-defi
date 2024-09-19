// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { TimelockOpenEnded } from "@credbull/timelock/TimelockOpenEnded.sol";
import { SimpleIERC1155Mintable } from "@test/src/interest/SimpleIERC1155Mintable.t.sol";
import { IERC5679Ext1155 } from "@credbull/interest/IERC5679Ext1155.sol";

import { Test } from "forge-std/Test.sol";

struct Deposit {
    uint256 depositPeriod;
    uint256 amount;
}

contract TimelockOpenEndedTest is Test {
    TimelockOpenEnded internal timelock; //
    IERC5679Ext1155 private deposits;
    IERC5679Ext1155 private unlockedDeposits;

    address internal owner = makeAddr("owner");
    address internal alice = makeAddr("alice");

    Deposit private depositDay1 = Deposit({ depositPeriod: 1, amount: 101 });
    Deposit private depositDay2 = Deposit({ depositPeriod: 2, amount: 202 });
    Deposit private depositDay3 = Deposit({ depositPeriod: 3, amount: 303 });

    function setUp() public {
        deposits = new SimpleIERC1155Mintable();
        unlockedDeposits = new SimpleIERC1155Mintable();
        timelock = new TimelockOpenEnded(deposits, unlockedDeposits);
    }

    function test__TimelockOpenEnded__NothingLocked() public view {
        assertEq(0, timelock.lockedAmount(alice, 1), "nothing should be locked");
    }

    function test__TimelockOpenEnded__Lock() public {
        vm.prank(owner);
        timelock.lock(alice, depositDay1.depositPeriod, depositDay1.amount);

        assertEq(depositDay1.amount, timelock.lockedAmount(alice, depositDay1.depositPeriod), "deposit not locked");
    }

    function test__TimelockOpenEnded__Unlock() public {
        vm.startPrank(owner);
        timelock.lock(alice, depositDay1.depositPeriod, depositDay1.amount);
        timelock.lock(alice, depositDay2.depositPeriod, depositDay2.amount);
        timelock.lock(alice, depositDay3.depositPeriod, depositDay3.amount);
        vm.stopPrank();

        // nothing unlocked yet
        assertEq(0, timelock.unlockedPeriods(alice).length, "nothing should be unlocked");

        // unlock deposit 2
        vm.prank(owner);
        timelock.unlock(alice, depositDay2.depositPeriod, depositDay2.amount);

        assertEq(
            depositDay2.amount,
            timelock.unlockedAmount(alice, depositDay2.depositPeriod),
            "deposit 2 should be unlocked"
        );
    }
}
