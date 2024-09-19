// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ITimelockOpenEnded } from "@credbull/timelock/ITimelockOpenEnded.sol";
import { TimelockOpenEnded } from "@credbull/timelock/TimelockOpenEnded.sol";
import { SimpleIERC1155Mintable } from "@test/src/interest/SimpleIERC1155Mintable.t.sol";
import { IERC5679Ext1155 } from "@credbull/interest/IERC5679Ext1155.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { Test } from "forge-std/Test.sol";

struct Deposit {
    uint256 depositPeriod;
    uint256 amount;
}

contract TimelockOpenEndedTest is Test {
    TimelockOpenEnded internal timelock; //
    IERC5679Ext1155 private depositLedger;

    address internal owner = makeAddr("owner");
    address internal alice = makeAddr("alice");

    Deposit private depositDay1 = Deposit({ depositPeriod: 1, amount: 100 });
    Deposit private depositDay2 = Deposit({ depositPeriod: 2, amount: 222 });
    Deposit private depositDay5 = Deposit({ depositPeriod: 5, amount: 550 });

    function setUp() public {
        depositLedger = new SimpleIERC1155Mintable();
        timelock = new TimelockOpenEnded(depositLedger);
    }

    function test__TimelockOpenEnded__NothingLocked() public view {
        assertEq(0, timelock.lockedAmount(alice, 1), "nothing should be locked");
    }

    function test__TimelockOpenEnded__Lock() public {
        vm.startPrank(owner);
        timelock.lock(alice, depositDay1.depositPeriod, depositDay1.amount);
        vm.stopPrank();

        assertEq(depositDay1.amount, timelock.lockedAmount(alice, depositDay1.depositPeriod), "deposit not locked");
    }

    function test__TimelockOpenEnded__GetAllUnlocks() public {
        vm.startPrank(owner);
        timelock.lock(alice, depositDay1.depositPeriod, depositDay1.amount);
        timelock.lock(alice, depositDay2.depositPeriod, depositDay2.amount);
        timelock.lock(alice, depositDay5.depositPeriod, depositDay5.amount);
        vm.stopPrank();

        // nothing unlocked yet
        assertEq(0, timelock.unlockedPeriods(alice).length, "nothing should be unlocked");
    }
}
