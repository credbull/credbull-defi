// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ITimelockOpenEnded } from "@credbull/timelock/ITimelockOpenEnded.sol";
import { IAsyncRedeem } from "@credbull/timelock/IAsyncRedeem.sol";
import { SimpleIERC1155Mintable } from "@test/src/interest/SimpleIERC1155Mintable.t.sol";
import { IERC5679Ext1155 } from "@credbull/interest/IERC5679Ext1155.sol";

import { Deposit } from "@test/src/timelock/TimelockTest.t.sol";
import { Test } from "forge-std/Test.sol";

contract SimpleAsyncRedeem is IAsyncRedeem {
    uint256 private period = 1;

    constructor(uint256 noticePeriod_, IERC5679Ext1155 deposits) IAsyncRedeem(noticePeriod_, deposits) { }

    /// @notice Returns the current period.
    function currentPeriod() public view override returns (uint256 currentPeriod_) {
        return period;
    }

    /// @notice Returns the current period.
    function setCurrentPeriod(uint256 currentPeriod_) public {
        period = currentPeriod_;
    }
}

contract AsyncRedeemTest is Test {
    SimpleAsyncRedeem internal asyncRedeem;
    IERC5679Ext1155 private deposits;

    uint256 private constant NOTICE_PERIOD = 1;

    address internal owner = makeAddr("owner");
    address internal alice = makeAddr("alice");

    Deposit private depositDay1 = Deposit({ depositPeriod: 1, amount: 101 });
    Deposit private depositDay2 = Deposit({ depositPeriod: 2, amount: 202 });
    Deposit private depositDay3 = Deposit({ depositPeriod: 3, amount: 303 });

    function setUp() public {
        deposits = new SimpleIERC1155Mintable();
        asyncRedeem = new SimpleAsyncRedeem(NOTICE_PERIOD, deposits);
    }

    // Scenario S6: User tries to redeem the Principal the same day they request redemption - revert
    // TODO TimeLock: Scenario S5: User tries to redeem the APY the same day they request redemption - revert (// TODO - add check for yield - revert if same day)
    function test__AsyncRedeemTest__RedeemSameDayFails() public {
        vm.prank(alice);
        asyncRedeem.lock(alice, depositDay1.depositPeriod, depositDay1.amount);

        vm.expectRevert(
            abi.encodeWithSelector(
                ITimelockOpenEnded.ITimelockOpenEnded__RequestedUnlockedBalanceInsufficient.selector,
                alice,
                0,
                depositDay1.amount
            )
        );
        asyncRedeem.redeem(depositDay1.amount, alice, alice, depositDay1.depositPeriod, depositDay1.depositPeriod);

        vm.expectRevert(
            abi.encodeWithSelector(
                ITimelockOpenEnded.ITimelockOpenEnded__NoticePeriodInsufficient.selector,
                alice,
                depositDay1.depositPeriod,
                depositDay1.depositPeriod + NOTICE_PERIOD
            )
        );
        asyncRedeem.requestRedeem(depositDay1.amount, alice, depositDay1.depositPeriod, depositDay1.depositPeriod);
    }

    // Scenario S6: User tries to redeem the Principal the same day they request redemption - revert
    // TODO TimeLock: Scenario S5: User tries to redeem the APY the same day they request redemption - revert (// TODO - add check for yield - revert if same day)
    function test__AsyncRedeemTest__RedeemSucceedsWithNotice() public {
        vm.prank(alice);
        asyncRedeem.lock(alice, depositDay1.depositPeriod, depositDay1.amount);
        assertEq(depositDay1.amount, asyncRedeem.lockedAmount(alice, depositDay1.depositPeriod), "deposit not locked");

        uint256 redeemPeriod = depositDay1.depositPeriod + NOTICE_PERIOD;

        asyncRedeem.requestRedeem(depositDay1.amount, alice, depositDay1.depositPeriod, redeemPeriod);

        asyncRedeem.setCurrentPeriod(redeemPeriod); // warp to redeemPeriod
        asyncRedeem.redeem(depositDay1.amount, alice, alice, depositDay1.depositPeriod, redeemPeriod); // should succeed

        assertEq(0, asyncRedeem.lockedAmount(alice, depositDay1.depositPeriod), "deposit lock not released");

        uint256 depositAtDepositPeriod = asyncRedeem.DEPOSITS().balanceOf(alice, depositDay1.depositPeriod);
        assertEq(0, depositAtDepositPeriod, "deposits should be redeemed");
    }
}
