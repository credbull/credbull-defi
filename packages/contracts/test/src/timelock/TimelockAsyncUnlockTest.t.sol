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

    function test__TimelockAsyncUnlock__RequestAndUnlockSucceeds() public {
        vm.prank(alice);
        asyncUnlock.lock(alice, depositDay1.depositPeriod, depositDay1.amount);
        assertEq(depositDay1.amount, asyncUnlock.lockedAmount(alice, depositDay1.depositPeriod), "deposit not locked");

        // uint256 unlockPeriod = depositDay1.depositPeriod + NOTICE_PERIOD;

        // request unlock
        vm.prank(alice);
        asyncUnlock.requestUnlock(alice, depositDay1.depositPeriod, depositDay1.amount);

        assertEq(
            depositDay1.amount,
            asyncUnlock.unlockRequested(alice, depositDay1.depositPeriod),
            "unlockRequest should be created"
        );
    }
}
