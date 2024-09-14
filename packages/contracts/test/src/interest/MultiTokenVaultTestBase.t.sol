// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { MultiTokenVault } from "@credbull/interest/MultiTokenVault.sol";
import { CalcInterestMetadata } from "@credbull/interest/CalcInterestMetadata.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { Test } from "forge-std/Test.sol";
import { ITenorable } from "@credbull/interest/ITenorable.sol";

abstract contract MultiTokenVaultTestBase is Test {
    using Math for uint256;

    uint256 public constant TOLERANCE = 10; // with 6 decimals, diff of 0.000005

    address internal owner = makeAddr("owner");
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");

    function testVaultAtPeriods(uint256 principal, MultiTokenVault vault, uint256 redeemPeriod) internal {
        uint256[5] memory depositPeriodsArr = [0, 1, redeemPeriod - 1, redeemPeriod, redeemPeriod + 1];

        // Iterate through the lock periods and calculate the principal for each
        for (uint256 i = 0; i < depositPeriodsArr.length; i++) {
            uint256 depositPeriod = depositPeriodsArr[i];

            testConvertToAssetAndSharesAtPeriod(principal, vault, depositPeriod); // previews only
            testPreviewDepositAndPreviewRedeem(principal, vault, depositPeriod); // previews only
            testDepositAndRedeemAtPeriod(owner, alice, principal, vault, depositPeriod); // actual deposits/redeems
        }
    }

    // verify convertToAssets and convertToShares.  These are a "preview" and do NOT update vault assets or shares.
    function testConvertToAssetAndSharesAtPeriod(uint256 principal, MultiTokenVault vault, uint256 depositPeriod)
        internal
        virtual
    {
        uint256 redeemPeriod = depositPeriod + getTenor(vault);

        uint256 prevVaultPeriodsElapsed = vault.getCurrentTimePeriodsElapsed(); // save previous state for later
        uint256 expectedAssetsAtRedeem = principal + vault.calcYield(principal, depositPeriod, redeemPeriod);

        // ------------------- check toShares/toAssets - specified period -------------------
        uint256 sharesAtPeriod = vault.convertToSharesForDepositPeriod(principal, depositPeriod);

        assertApproxEqAbs(
            expectedAssetsAtRedeem,
            vault.convertToAssetsForDepositPeriod(sharesAtPeriod, depositPeriod, redeemPeriod),
            TOLERANCE,
            assertMsg("yield does not equal principal + interest", vault, depositPeriod)
        );

        // ------------------- check toShares/toAssets - current period -------------------
        vault.setCurrentTimePeriodsElapsed(depositPeriod); // set deposit numPeriods
        uint256 actualShares = vault.convertToShares(principal);

        vault.setCurrentTimePeriodsElapsed(redeemPeriod); // set redeem numPeriods
        assertApproxEqAbs(
            expectedAssetsAtRedeem,
            vault.convertToAssetsForDepositPeriod(actualShares, depositPeriod),
            TOLERANCE,
            assertMsg("toShares/toAssets yield does not equal principal + interest", vault, depositPeriod)
        );

        vault.setCurrentTimePeriodsElapsed(prevVaultPeriodsElapsed); // restore the vault to previous state
    }

    // verify previewDeposit and previewRedeem.  These are a "preview" and do NOT update vault assets or shares.
    function testPreviewDepositAndPreviewRedeem(uint256 principal, MultiTokenVault vault, uint256 depositPeriod)
        internal
        virtual
    {
        uint256 tenor = getTenor(vault);

        uint256 prevVaultPeriodsElapsed = vault.getCurrentTimePeriodsElapsed();
        uint256 expectedAssetsAtRedeem = principal + vault.calcYield(principal, 0, tenor);

        // ------------------- check previewDeposit/previewRedeem - current period -------------------
        vault.setCurrentTimePeriodsElapsed(depositPeriod); // set deposit period prior to deposit
        uint256 actualSharesDeposit = vault.previewDeposit(principal);

        vault.setCurrentTimePeriodsElapsed(depositPeriod + tenor); // warp to redeem / withdraw

        // check previewRedeem
        assertApproxEqAbs(
            expectedAssetsAtRedeem,
            vault.previewRedeemForDepositPeriod(actualSharesDeposit, depositPeriod),
            TOLERANCE,
            assertMsg("previewDeposit/previewRedeem yield does not equal principal + interest", vault, depositPeriod)
        );

        // ------------------- check previewWithdraw - current period -------------------
        vm.expectRevert(abi.encodeWithSelector(MultiTokenVault.UnsupportedFunction.selector, "previewWithdraw"));
        vault.previewWithdraw(principal); // previewWithdraw not currently implemented, expect revert

        vault.setCurrentTimePeriodsElapsed(prevVaultPeriodsElapsed);
    }

    // verify deposit and redeem.  These update vault assets and shares.
    function testDepositAndRedeemAtPeriod(
        address _owner,
        address receiver,
        uint256 principal,
        MultiTokenVault vault,
        uint256 depositPeriod
    ) internal virtual {
        IERC20 asset = IERC20(vault.asset());
        uint256 tenor = getTenor(vault);

        // capture state before for validations
        uint256 prevVaultPeriodsElapsed = vault.getCurrentTimePeriodsElapsed();
        uint256 prevReceiverAssetBalance = asset.balanceOf(receiver);

        // ------------------- deposit -------------------
        uint256 shares = testDepositOnly(receiver, principal, vault, depositPeriod);

        // ------------------- prep redeem -------------------
        uint256 expectedYield = vault.calcYield(principal, 0, tenor);
        vm.startPrank(_owner);
        transferAndAssert(asset, _owner, address(vault), expectedYield); // fund the vault to cover redeem
        vm.stopPrank();

        // ------------------- redeem -------------------
        vault.setCurrentTimePeriodsElapsed(depositPeriod + tenor); // warp the vault to redeem period

        vm.startPrank(receiver);
        uint256 assets = vault.redeemForDepositPeriod(shares, receiver, receiver, depositPeriod);
        vm.stopPrank();
        assertApproxEqAbs(
            prevReceiverAssetBalance + expectedYield,
            asset.balanceOf(receiver),
            TOLERANCE,
            assertMsg("receiver did not receive the correct yield", vault, depositPeriod)
        );

        assertApproxEqAbs(
            principal + expectedYield,
            assets,
            TOLERANCE,
            assertMsg("assets does not equal principal + interest", vault, depositPeriod)
        );

        // ------------------- withdraw -------------------
        vm.expectRevert(abi.encodeWithSelector(MultiTokenVault.UnsupportedFunction.selector, "withdraw"));
        vault.withdraw(principal, receiver, receiver); // withdraw not currently implemented, expect revert

        vault.setCurrentTimePeriodsElapsed(prevVaultPeriodsElapsed); // restore the vault to previous state
    }

    // verify deposit and redeem.  These update vault assets and shares.
    function testDepositOnly(address receiver, uint256 principal, MultiTokenVault vault, uint256 depositPeriod)
        internal
        virtual
        returns (uint256 _shares)
    {
        IERC20 asset = IERC20(vault.asset());

        // capture state before for validations
        uint256 prevVaultPeriodsElapsed = vault.getCurrentTimePeriodsElapsed();
        uint256 prevReceiverVaultBalance = vault.balanceOf(receiver);

        // ------------------- deposit -------------------
        vault.setCurrentTimePeriodsElapsed(depositPeriod); // set deposit numPeriods
        vm.startPrank(receiver);
        assertGe(
            asset.balanceOf(receiver), principal, assertMsg("not enough assets for deposit ", vault, depositPeriod)
        );
        asset.approve(address(vault), principal); // grant the vault allowance
        uint256 shares = vault.deposit(principal, receiver); // now deposit

        vm.stopPrank();
        assertEq(
            prevReceiverVaultBalance + shares,
            vault.balanceOf(receiver),
            assertMsg("receiver did not receive the correct vault shares ", vault, depositPeriod)
        );

        vault.setCurrentTimePeriodsElapsed(prevVaultPeriodsElapsed);

        return shares;
    }

    // represents the offset from depositPeriod to redeemPeriod, e.g.
    // returns 30, even if deposit on day 1 or day 2
    function getTenor(MultiTokenVault vault) internal view returns (uint256 redeemPeriod) {
        // vault only works with a known-tenor.  so revert if not Tenorable.
        ITenorable tenorable = ITenorable(address(vault));

        return tenorable.getTenor();
    }

    function assertMsg(string memory prefix, MultiTokenVault vault, uint256 numPeriods)
        internal
        view
        returns (string memory)
    {
        string memory vaultToString = "";

        // Type-safe encoding of the function call
        (bool success, bytes memory result) =
            address(vault).staticcall(abi.encodeCall(CalcInterestMetadata.toString, ()));

        if (success && result.length > 0) {
            // Decode the result if the call was successful
            vaultToString = abi.decode(result, (string));
        } else {
            vaultToString = "";
        }

        return string.concat(prefix, vaultToString, " timePeriod= ", vm.toString(numPeriods));
    }

    function transferAndAssert(IERC20 _token, address fromAddress, address toAddress, uint256 amount) internal {
        uint256 beforeBalance = _token.balanceOf(toAddress);

        vm.startPrank(fromAddress);
        _token.transfer(toAddress, amount);
        vm.stopPrank();

        assertEq(beforeBalance + amount, _token.balanceOf(toAddress));
    }
}
