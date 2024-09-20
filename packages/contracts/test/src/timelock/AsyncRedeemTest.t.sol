// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ITimelockOpenEnded } from "@credbull/timelock/ITimelockOpenEnded.sol";
import { TimelockOpenEnded } from "@credbull/timelock/TimelockOpenEnded.sol";
import { IAsyncRedeem } from "@credbull/timelock/IAsyncRedeem.sol";
import { SimpleIERC1155Mintable } from "@test/src/interest/SimpleIERC1155Mintable.t.sol";
import { IERC5679Ext1155 } from "@credbull/interest/IERC5679Ext1155.sol";

import { Deposit } from "@test/src/timelock/TimelockTest.t.sol";
import { Test } from "forge-std/Test.sol";

contract SimpleAsyncRedeem is TimelockOpenEnded, IAsyncRedeem {
    constructor(IERC5679Ext1155 deposits, IERC5679Ext1155 unlockedDeposits)
        TimelockOpenEnded(deposits, unlockedDeposits)
    { }

    /// @notice Requests redemption of `shares` for assets, which will be transferred to `receiver` after the `redeemPeriod`.
    // TODO - confirm if we want the concept of shares here, or are these just assets?
    function requestRedeem(
        uint256 shares,
        address, /* receiver */
        address owner,
        uint256 depositPeriod,
        uint256 /* redeemPeriod */
    ) external returns (uint256 assets) {
        unlock(owner, depositPeriod, shares); // TODO - maybe we want the redeem period in unlock

        return shares;
    }

    /// @notice Processes the redemption of `shares` for assets after the `redeemPeriod`, transferring to `receiver`.
    // TODO - confirm if we want the concept of shares here, or are these just assets?
    function redeem(
        uint256 shares,
        address, /* receiver */
        address owner,
        uint256 depositPeriod,
        uint256 /* redeemPeriod */
    ) external view returns (uint256 assets) {
        uint256 unlockedAmount_ = unlockedAmount(owner, depositPeriod);
        if (shares > unlockedAmount_) {
            revert ITimelockOpenEnded__InsufficientUnlockedBalance(owner, unlockedAmount_, shares);
        }
        return 0;
    }
}

contract AsyncRedeemTest is Test {
    IAsyncRedeem internal asyncRedeem; //
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
        asyncRedeem = new SimpleAsyncRedeem(deposits, unlockedDeposits);
    }

    // Scenario S6: User tries to redeem the Principal the same day they request redemption - revert
    // TODO TimeLock: Scenario S5: User tries to redeem the APY the same day they request redemption - revert
    function test__AsyncRedeemTest__RedeemSameDay() public {
        vm.prank(alice);
        asyncRedeem.lock(alice, depositDay1.depositPeriod, depositDay1.amount);

        vm.expectRevert(
            abi.encodeWithSelector(
                ITimelockOpenEnded.ITimelockOpenEnded__InsufficientUnlockedBalance.selector,
                alice,
                0,
                depositDay1.amount
            )
        );
        asyncRedeem.redeem(depositDay1.amount, alice, alice, depositDay1.depositPeriod, depositDay1.depositPeriod);

        // TODO - add check for requestRedeem - revert if same day

        // TODO - add check for yield - revert if same day
    }
}
