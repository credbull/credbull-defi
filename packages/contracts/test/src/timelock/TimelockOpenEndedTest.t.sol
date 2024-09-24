// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { TimelockOpenEnded } from "@credbull/timelock/TimelockOpenEnded.sol";
import { SimpleIERC1155Mintable } from "@test/src/interest/SimpleIERC1155Mintable.t.sol";
import { IERC5679Ext1155 } from "@credbull/interest/IERC5679Ext1155.sol";

import { Deposit } from "@test/src/timelock/TimelockTest.t.sol";
import { Test } from "forge-std/Test.sol";

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
        timelock = new TimelockOpenEndedMock(deposits, unlockedDeposits);
    }

    function test__TimelockOpenEnded__NoDeposits() public view {
        assertEq(0, timelock.lockedAmount(alice, 1), "no deposit - nothing should be locked");
        assertEq(0, timelock.unlockedPeriods(alice, 0, 10).length, "no deposit - no period should be unlocked");
        assertEq(0, timelock.unlockedAmount(alice, 1), "no deposit - no amount should be unlocked");
    }

    function test__TimelockOpenEnded__Deposit() public {
        vm.prank(alice);
        timelock.lock(alice, depositDay1.depositPeriod, depositDay1.amount);

        assertEq(
            depositDay1.amount, timelock.lockedAmount(alice, depositDay1.depositPeriod), "deposit should be locked"
        );
        assertEq(0, timelock.unlockedAmount(alice, depositDay1.depositPeriod), "nothing should be unlocked");
    }

    function test__TimelockOpenEnded__DepositAndUnlock() public {
        vm.startPrank(alice);
        timelock.lock(alice, depositDay1.depositPeriod, depositDay1.amount);
        timelock.lock(alice, depositDay2.depositPeriod, depositDay2.amount);
        timelock.lock(alice, depositDay3.depositPeriod, depositDay3.amount);
        vm.stopPrank();

        // nothing unlocked yet
        assertEq(0, timelock.unlockedPeriods(alice, 0, depositDay3.depositPeriod).length, "nothing should be unlocked");
        assertEq(
            depositDay2.amount,
            timelock.maxUnlockAmount(alice, depositDay2.depositPeriod),
            "entire deposit should be unlockable"
        );

        // unlock deposit 2
        vm.prank(alice);
        timelock.unlock(alice, depositDay2.depositPeriod, depositDay2.amount);

        uint256[] memory unlockPeriods = timelock.unlockedPeriods(alice, 0, depositDay3.depositPeriod);
        assertEq(1, unlockPeriods.length, "exactly one period should be unlocked");
        assertEq(depositDay2.depositPeriod, unlockPeriods[0], "deposit2 period should be unlocked");

        assertEq(
            depositDay2.amount,
            timelock.unlockedAmount(alice, depositDay2.depositPeriod),
            "deposit2 amount should be unlocked"
        );
    }
}

contract TimelockOpenEndedMock is TimelockOpenEnded {
    IERC5679Ext1155 public immutable UNLOCKED_DEPOSITS;

    constructor(IERC5679Ext1155 deposits, IERC5679Ext1155 unlockedDeposits) TimelockOpenEnded(deposits) {
        UNLOCKED_DEPOSITS = unlockedDeposits;
    }

    /// @notice Unlocks `amount` of tokens for `account` from the given `depositPeriod`.
    function unlock(address account, uint256 depositPeriod, uint256 amount) public override {
        uint256 maxUnlockableAmount_ = maxUnlockAmount(account, depositPeriod);
        if (amount > maxUnlockableAmount_) {
            revert ITimelockOpenEnded__LockedBalanceInsufficient(account, maxUnlockableAmount_, amount);
        }

        UNLOCKED_DEPOSITS.safeMint(account, depositPeriod, amount, "");
    }

    /// @notice Returns the amount of tokens unlocked for `account` from the given `depositPeriod`.
    function unlockedAmount(address account, uint256 depositPeriod)
        public
        view
        override
        returns (uint256 unlockedAmount_)
    {
        return UNLOCKED_DEPOSITS.balanceOf(account, depositPeriod);
    }

    function currentPeriod() public pure override returns (uint256 currentPeriod_) {
        return 0;
    }
}
