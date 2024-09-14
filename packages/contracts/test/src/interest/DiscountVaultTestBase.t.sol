// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IDiscountVault } from "@credbull/interest/IDiscountVault.sol";
import { CalcInterestMetadata } from "@credbull/interest/CalcInterestMetadata.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { Test } from "forge-std/Test.sol";
import { ITenorable } from "../../../src/interest/ITenorable.sol";

abstract contract DiscountVaultTestBase is Test {
    using Math for uint256;

    uint256 public constant TOLERANCE = 5; // with 6 decimals, diff of 0.000005

    address internal owner = makeAddr("owner");
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");

    function testVaultAtPeriods(uint256 principal, IDiscountVault vault, uint256 redeemPeriod) internal {
        uint256[5] memory numTimePeriodsElapsedArr = [0, 1, redeemPeriod - 1, redeemPeriod, redeemPeriod + 1];

        // Iterate through the lock periods and calculate the principal for each
        for (uint256 i = 0; i < numTimePeriodsElapsedArr.length; i++) {
            uint256 numTimePeriodsElapsed = numTimePeriodsElapsedArr[i];

            testConvertToAssetAndSharesAtPeriod(principal, vault, numTimePeriodsElapsed); // previews only
            testPreviewDepositAndPreviewRedeem(principal, vault, numTimePeriodsElapsed); // previews only
            testDepositAndRedeemAtPeriod(owner, alice, principal, vault, numTimePeriodsElapsed); // actual deposits/redeems
        }
    }

    // verify convertToAssets and convertToShares.  These are a "preview" and do NOT update vault assets or shares.
    function testConvertToAssetAndSharesAtPeriod(uint256 principal, IDiscountVault vault, uint256 numTimePeriods)
        internal
        virtual
    {
        uint256 tenor = getTenor(vault);

        uint256 prevVaultTimePeriodsElapsed = vault.getCurrentTimePeriodsElapsed(); // save previous state for later
        uint256 expectedAssetsAtRedeem = principal + vault.calcYield(principal, 0, tenor);

        // ------------------- check toShares/toAssets - specified period -------------------
        uint256 sharesAtPeriod = vault.convertToSharesAtPeriod(principal, numTimePeriods);

        assertApproxEqAbs(
            expectedAssetsAtRedeem,
            vault.convertToAssetsAtPeriod(sharesAtPeriod, numTimePeriods + tenor),
            TOLERANCE,
            assertMsg("yield does not equal principal + interest", vault, numTimePeriods)
        );

        // ------------------- check toShares/toAssets - current period -------------------
        vault.setCurrentTimePeriodsElapsed(numTimePeriods); // set deposit numTimePeriods
        uint256 actualShares = vault.convertToShares(principal);

        vault.setCurrentTimePeriodsElapsed(numTimePeriods + tenor); // set redeem numTimePeriods
        assertApproxEqAbs(
            expectedAssetsAtRedeem,
            vault.convertToAssets(actualShares),
            TOLERANCE,
            assertMsg("toShares/toAssets yield does not equal principal + interest", vault, numTimePeriods)
        );

        vault.setCurrentTimePeriodsElapsed(prevVaultTimePeriodsElapsed); // restore the vault to previous state
    }

    // verify previewDeposit and previewRedeem.  These are a "preview" and do NOT update vault assets or shares.
    function testPreviewDepositAndPreviewRedeem(uint256 principal, IDiscountVault vault, uint256 numTimePeriods)
        internal
        virtual
    {
        uint256 tenor = getTenor(vault);

        uint256 prevVaultTimePeriodsElapsed = vault.getCurrentTimePeriodsElapsed();
        uint256 expectedAssetsAtRedeem = principal + vault.calcYield(principal, 0, tenor);

        // ------------------- check previewDeposit/previewRedeem - current period -------------------
        vault.setCurrentTimePeriodsElapsed(numTimePeriods); // set deposit period prior to deposit
        uint256 actualSharesDeposit = vault.previewDeposit(principal);

        vault.setCurrentTimePeriodsElapsed(numTimePeriods + tenor); // warp to redeem / withdraw

        // check previewRedeem
        assertApproxEqAbs(
            expectedAssetsAtRedeem,
            vault.previewRedeem(actualSharesDeposit),
            TOLERANCE,
            assertMsg("previewDeposit/previewRedeem yield does not equal principal + interest", vault, numTimePeriods)
        );

        // ------------------- check previewWithdraw - current period -------------------
        // as per definition - should be the same as convertToShares
        assertEq(
            vault.previewWithdraw(principal),
            actualSharesDeposit,
            assertMsg("previewWithdraw incorrect - principal", vault, numTimePeriods)
        );

        vault.setCurrentTimePeriodsElapsed(prevVaultTimePeriodsElapsed);
    }

    // verify deposit and redeem.  These update vault assets and shares.
    function testDepositAndRedeemAtPeriod(
        address _owner,
        address receiver,
        uint256 principal,
        IDiscountVault vault,
        uint256 numTimePeriods
    ) internal virtual {
        IERC20 asset = IERC20(vault.asset());
        uint256 tenor = getTenor(vault);

        // capture state before for validations
        uint256 prevVaultTimePeriodsElapsed = vault.getCurrentTimePeriodsElapsed();
        uint256 prevReceiverVaultBalance = vault.balanceOf(receiver);
        uint256 prevReceiverAssetBalance = asset.balanceOf(receiver);

        // ------------------- deposit -------------------
        vault.setCurrentTimePeriodsElapsed(numTimePeriods); // set deposit numTimePeriods
        vm.startPrank(receiver);
        assertGe(
            asset.balanceOf(receiver), principal, assertMsg("not enough assets for deposit ", vault, numTimePeriods)
        );
        asset.approve(address(vault), principal); // grant the vault allowance
        uint256 shares = vault.deposit(principal, receiver); // now deposit

        vm.stopPrank();
        assertEq(
            prevReceiverVaultBalance + shares,
            vault.balanceOf(receiver),
            assertMsg("receiver did not receive the correct vault shares ", vault, numTimePeriods)
        );

        // ------------------- prep redeem -------------------
        uint256 expectedYield = vault.calcYield(principal, 0, tenor);
        vm.startPrank(_owner);
        transferAndAssert(asset, _owner, address(vault), expectedYield); // fund the vault to cover redeem
        vm.stopPrank();

        // ------------------- redeem -------------------
        vault.setCurrentTimePeriodsElapsed(numTimePeriods + tenor); // warp the vault to redeem period

        vm.startPrank(receiver);
        uint256 assets = vault.redeem(shares, receiver, receiver);
        vm.stopPrank();
        assertApproxEqAbs(
            prevReceiverAssetBalance + expectedYield,
            asset.balanceOf(receiver),
            TOLERANCE,
            assertMsg("receiver did not receive the correct yield", vault, numTimePeriods)
        );

        assertApproxEqAbs(
            principal + expectedYield,
            assets,
            TOLERANCE,
            assertMsg("assets does not equal principal + interest", vault, numTimePeriods)
        );

        vault.setCurrentTimePeriodsElapsed(prevVaultTimePeriodsElapsed); // restore the vault to previous state
    }

    // represents the offset from depositPeriod to redeemPeriod, e.g.
    // returns 30, even if deposit on day 1 or day 2
    function getTenor(IDiscountVault vault) internal view returns (uint256 redeemTimePeriod) {
        // TODO: change to use IERC165 - for now just assume supports ITenorable
        ITenorable tenorable = ITenorable(address(vault));

        return tenorable.getTenor();
    }

    function assertMsg(string memory prefix, IDiscountVault vault, uint256 numTimePeriods)
        internal
        view
        returns (string memory)
    {
        CalcInterestMetadata calcInterest = CalcInterestMetadata(address(vault));

        return string.concat(prefix, calcInterest.toString(), " timePeriod= ", vm.toString(numTimePeriods));
    }

    function transferAndAssert(IERC20 _token, address fromAddress, address toAddress, uint256 amount) internal {
        uint256 beforeBalance = _token.balanceOf(toAddress);

        vm.startPrank(fromAddress);
        _token.transfer(toAddress, amount);
        vm.stopPrank();

        assertEq(beforeBalance + amount, _token.balanceOf(toAddress));
    }
}
