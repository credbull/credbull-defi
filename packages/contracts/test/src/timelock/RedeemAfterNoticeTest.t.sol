// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { RedeemAfterNotice } from "@credbull/timelock/RedeemAfterNotice.sol";
import { SimpleIERC1155Mintable } from "@test/src/interest/SimpleIERC1155Mintable.t.sol";
import { IERC5679Ext1155 } from "@credbull/interest/IERC5679Ext1155.sol";

import { Deposit } from "@test/src/timelock/TimelockTest.t.sol";
import { Test } from "forge-std/Test.sol";

contract SimpleRedeemAfterNotice is RedeemAfterNotice {
    uint256 private period = 0;

    constructor(uint256 noticePeriod_, IERC5679Ext1155 deposits) RedeemAfterNotice(noticePeriod_, deposits) { }

    /// @notice Returns the current period.
    function currentPeriod() public view override returns (uint256 currentPeriod_) {
        return period;
    }

    /// @notice Returns the current period.
    function setCurrentPeriod(uint256 currentPeriod_) public {
        period = currentPeriod_;
    }
}

contract RedeemAfterNoticeTest is Test {
    SimpleRedeemAfterNotice internal asyncRedeem;
    IERC5679Ext1155 private deposits;

    uint256 private constant NOTICE_PERIOD = 1;

    address internal owner = makeAddr("owner");
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");

    Deposit private depositDay1 = Deposit({ depositPeriod: 1, amount: 101 });
    Deposit private depositDay2 = Deposit({ depositPeriod: 2, amount: 202 });
    Deposit private depositDay3 = Deposit({ depositPeriod: 3, amount: 303 });

    function setUp() public {
        deposits = new SimpleIERC1155Mintable();
        asyncRedeem = new SimpleRedeemAfterNotice(NOTICE_PERIOD, deposits);
    }

    function test__RedeemAfterNotice__RequestAndRedeemSucceeds() public {
        vm.prank(alice);
        asyncRedeem.lock(alice, depositDay1.depositPeriod, depositDay1.amount);
        assertEq(depositDay1.amount, asyncRedeem.lockedAmount(alice, depositDay1.depositPeriod), "deposit not locked");

        uint256 redeemPeriod = depositDay1.depositPeriod + NOTICE_PERIOD;

        // request redeem
        vm.prank(alice);
        asyncRedeem.requestRedeem(depositDay1.amount, alice, depositDay1.depositPeriod, redeemPeriod);

        // warp to redeem period
        asyncRedeem.setCurrentPeriod(redeemPeriod);

        // now redeem
        vm.prank(alice);
        asyncRedeem.redeem(depositDay1.amount, alice, alice, depositDay1.depositPeriod, redeemPeriod);

        assertEq(0, asyncRedeem.lockedAmount(alice, depositDay1.depositPeriod), "deposit lock not released");
        assertEq(0, asyncRedeem.DEPOSITS().balanceOf(alice, depositDay1.depositPeriod), "deposits should be redeemed");
    }

    // Scenario S6: User tries to redeem the Principal the same day they request redemption - revert
    // TODO TimeLock: Scenario S5: User tries to redeem the APY the same day they request redemption - revert (// TODO - add check for yield - revert if same day)
    function test__RedeemAfterNotice_RequestRedeemSameDayFails() public {
        vm.prank(alice);
        asyncRedeem.lock(alice, depositDay1.depositPeriod, depositDay1.amount);

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                RedeemAfterNotice.RedeemAfterNotice__NoticePeriodInsufficient.selector,
                alice,
                depositDay1.depositPeriod,
                depositDay1.depositPeriod + NOTICE_PERIOD
            )
        );
        asyncRedeem.requestRedeem(depositDay1.amount, alice, depositDay1.depositPeriod, depositDay1.depositPeriod);
    }

    function test__RedeemAfterNotice__RedeemPriorToRedeemPeriodFails() public {
        uint256 timeLockCurrentPeriod = asyncRedeem.currentPeriod();
        uint256 redeemPeriod = depositDay1.depositPeriod + NOTICE_PERIOD;

        // fail - not yet at the redeemPeriod
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                RedeemAfterNotice.RedeemAfterNotice__RedeemPeriodNotReached.selector,
                alice,
                timeLockCurrentPeriod,
                redeemPeriod
            )
        );
        asyncRedeem.redeem(depositDay1.amount, alice, alice, depositDay1.depositPeriod, redeemPeriod);
    }

    function test__RedeemAfterNotice__RedeemWithoutRequestFails() public {
        uint256 redeemPeriod = depositDay1.depositPeriod + NOTICE_PERIOD;

        // warp to redeem period
        asyncRedeem.setCurrentPeriod(redeemPeriod);

        // fail - no redeemRequest
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                RedeemAfterNotice.RedeemAfterNotice__RequestedRedeemAmountInsufficient.selector,
                alice,
                0,
                depositDay1.amount
            )
        );
        asyncRedeem.redeem(depositDay1.amount, alice, alice, depositDay1.depositPeriod, redeemPeriod);
    }

    function test__AsyncRedeemTest__OnlyDepositorCanRequestOrRedeem() public {
        vm.prank(alice);
        asyncRedeem.lock(alice, depositDay1.depositPeriod, depositDay1.amount);

        uint256 redeemPeriod = depositDay1.depositPeriod + NOTICE_PERIOD;

        vm.prank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(RedeemAfterNotice.RedeemAfterNotice__RequesterNotOwner.selector, bob, alice)
        );
        asyncRedeem.requestRedeem(depositDay1.amount, alice, depositDay1.depositPeriod, redeemPeriod);

        // warp to redeem period
        asyncRedeem.setCurrentPeriod(redeemPeriod);

        vm.prank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(RedeemAfterNotice.RedeemAfterNotice__RequesterNotOwner.selector, bob, alice)
        );
        asyncRedeem.redeem(depositDay1.amount, bob, alice, depositDay1.depositPeriod, redeemPeriod);
    }
}
