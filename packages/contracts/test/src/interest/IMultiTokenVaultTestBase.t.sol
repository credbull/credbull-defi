// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IMultiTokenVault } from "@credbull/interest/IMultiTokenVault.sol";
import { CalcInterestMetadata } from "@credbull/interest/CalcInterestMetadata.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { Test } from "forge-std/Test.sol";
import { ITenorable } from "@credbull/interest/ITenorable.sol";

abstract contract IMultiTokenVaultTestBase is Test {
    using Math for uint256;

    uint256 public constant TOLERANCE = 5; // with 6 decimals, diff of 0.000010

    address internal owner = makeAddr("owner");
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");

    function testVaultAtPeriods(uint256 principal, IMultiTokenVault vault, uint256 depositPeriod, uint256 redeemPeriod)
        internal
    {
        uint256[6] memory offsetNumPeriodsArr = [0, 1, 2, redeemPeriod - 1, redeemPeriod, redeemPeriod + 1];

        for (uint256 i = 0; i < offsetNumPeriodsArr.length; i++) {
            uint256 offsetNumPeriods = offsetNumPeriodsArr[i];

            _testVaultAtPeriod(principal, vault, depositPeriod + offsetNumPeriods, redeemPeriod + offsetNumPeriods);
        }
    }

    function _testVaultAtPeriod(uint256 principal, IMultiTokenVault vault, uint256 depositPeriod, uint256 redeemPeriod)
        internal
    {
        testConvertToAssetAndSharesAtPeriod(principal, vault, depositPeriod, redeemPeriod); // previews only
        testPreviewDepositAndPreviewRedeem(principal, vault, depositPeriod, redeemPeriod); // previews only
        testDepositAndRedeemAtPeriod(owner, alice, principal, vault, depositPeriod, redeemPeriod); // actual deposits/redeems
    }

    // verify convertToAssets and convertToShares.  These are a "preview" and do NOT update vault assets or shares.
    function testConvertToAssetAndSharesAtPeriod(
        uint256 principal,
        IMultiTokenVault vault,
        uint256 depositPeriod,
        uint256 redeemPeriod
    ) internal virtual {
        uint256 prevVaultPeriodsElapsed = vault.getCurrentTimePeriodsElapsed(); // save previous state for later
        uint256 expectedAssetsAtRedeem = principal + vault.calcYield(principal, depositPeriod, redeemPeriod);

        // ------------------- check toShares/toAssets - specified period -------------------
        uint256 sharesAtPeriod = vault.convertToSharesForDepositPeriod(principal, depositPeriod);

        assertApproxEqAbs(
            expectedAssetsAtRedeem,
            vault.convertToAssetsForDepositPeriod(sharesAtPeriod, depositPeriod, redeemPeriod),
            TOLERANCE,
            _assertMsg("yield does not equal principal + interest", vault, depositPeriod)
        );

        // ------------------- check toShares/toAssets - current period -------------------
        vault.setCurrentTimePeriodsElapsed(depositPeriod); // set deposit numPeriods
        uint256 actualShares = vault.convertToShares(principal);

        vault.setCurrentTimePeriodsElapsed(redeemPeriod); // set redeem numPeriods
        assertApproxEqAbs(
            expectedAssetsAtRedeem,
            vault.convertToAssetsForDepositPeriod(actualShares, depositPeriod),
            TOLERANCE,
            _assertMsg("toShares/toAssets yield does not equal principal + interest", vault, depositPeriod)
        );

        vault.setCurrentTimePeriodsElapsed(prevVaultPeriodsElapsed); // restore the vault to previous state
    }

    // verify previewDeposit and previewRedeem.  These are a "preview" and do NOT update vault assets or shares.
    function testPreviewDepositAndPreviewRedeem(
        uint256 principal,
        IMultiTokenVault vault,
        uint256 depositPeriod,
        uint256 redeemPeriod
    ) internal virtual {
        uint256 prevVaultPeriodsElapsed = vault.getCurrentTimePeriodsElapsed();
        uint256 expectedAssetsAtRedeem = principal + vault.calcYield(principal, depositPeriod, redeemPeriod);

        // ------------------- check previewDeposit/previewRedeem - current period -------------------
        vault.setCurrentTimePeriodsElapsed(depositPeriod); // set deposit period prior to deposit
        uint256 actualSharesDeposit = vault.previewDeposit(principal);

        vault.setCurrentTimePeriodsElapsed(redeemPeriod); // warp to redeem / withdrawd

        // check previewRedeem
        assertApproxEqAbs(
            expectedAssetsAtRedeem,
            vault.previewRedeemForDepositPeriod(actualSharesDeposit, depositPeriod),
            TOLERANCE,
            _assertMsg("previewDeposit/previewRedeem yield does not equal principal + interest", vault, depositPeriod)
        );

        vault.setCurrentTimePeriodsElapsed(prevVaultPeriodsElapsed);
    }

    // verify deposit and redeem.  These update vault assets and shares.
    function testDepositAndRedeemAtPeriod(
        address _owner,
        address receiver,
        uint256 principal,
        IMultiTokenVault vault,
        uint256 depositPeriod,
        uint256 redeemPeriod
    ) internal virtual {
        IERC20 asset = vault.getAsset();

        // capture state before for validations
        uint256 prevVaultPeriodsElapsed = vault.getCurrentTimePeriodsElapsed();
        uint256 prevReceiverAssetBalance = asset.balanceOf(receiver);

        // ------------------- deposit -------------------
        uint256 shares = testDepositOnly(receiver, principal, vault, depositPeriod);

        // ------------------- prep redeem -------------------
        uint256 expectedYield = vault.calcYield(principal, depositPeriod, redeemPeriod);
        vm.startPrank(_owner);
        _transferAndAssert(asset, _owner, address(vault), expectedYield); // fund the vault to cover redeem
        vm.stopPrank();

        // ------------------- redeem -------------------
        vault.setCurrentTimePeriodsElapsed(redeemPeriod); // warp the vault to redeem period

        vm.startPrank(receiver);
        uint256 assets = vault.redeemForDepositPeriod(shares, receiver, receiver, depositPeriod);
        vm.stopPrank();
        assertApproxEqAbs(
            prevReceiverAssetBalance + expectedYield,
            asset.balanceOf(receiver),
            TOLERANCE,
            _assertMsg("receiver did not receive the correct yield", vault, depositPeriod)
        );

        assertApproxEqAbs(
            principal + expectedYield,
            assets,
            TOLERANCE,
            _assertMsg("assets does not equal principal + interest", vault, depositPeriod)
        );

        vault.setCurrentTimePeriodsElapsed(prevVaultPeriodsElapsed); // restore the vault to previous state
    }

    // verify deposit and redeem.  These update vault assets and shares.
    function testDepositOnly(address receiver, uint256 principal, IMultiTokenVault vault, uint256 depositPeriod)
        internal
        virtual
        returns (uint256 _shares)
    {
        IERC20 asset = vault.getAsset();

        // capture state before for validations
        uint256 prevVaultPeriodsElapsed = vault.getCurrentTimePeriodsElapsed();
        uint256 prevReceiverVaultBalance = vault.getSharesAtPeriod(receiver, depositPeriod);

        // ------------------- deposit -------------------
        vault.setCurrentTimePeriodsElapsed(depositPeriod); // set deposit numPeriods
        vm.startPrank(receiver);
        assertGe(
            asset.balanceOf(receiver), principal, _assertMsg("not enough assets for deposit ", vault, depositPeriod)
        );
        asset.approve(address(vault), principal); // grant the vault allowance
        uint256 shares = vault.deposit(principal, receiver); // now deposit

        vm.stopPrank();
        assertEq(
            prevReceiverVaultBalance + shares,
            vault.getSharesAtPeriod(receiver, depositPeriod),
            _assertMsg("receiver did not receive the correct vault shares ", vault, depositPeriod)
        );

        vault.setCurrentTimePeriodsElapsed(prevVaultPeriodsElapsed);

        return shares;
    }

    function _assertMsg(string memory prefix, IMultiTokenVault vault, uint256 numPeriods)
        internal
        view
        returns (string memory)
    {
        string memory vaultToString = string.concat(" Vault address= ", vm.toString(address(vault)));

        (bool success, bytes memory result) = address(vault).staticcall(abi.encodeWithSignature("toString()"));

        if (success && result.length > 0) {
            // Decode the result if the call was successful
            vaultToString = string.concat(vaultToString, " ", abi.decode(result, (string)));
        }

        return string.concat(prefix, vaultToString, " timePeriod= ", vm.toString(numPeriods));
    }

    function _transferAndAssert(IERC20 _token, address fromAddress, address toAddress, uint256 amount) internal {
        uint256 beforeBalance = _token.balanceOf(toAddress);

        vm.startPrank(fromAddress);
        _token.transfer(toAddress, amount);
        vm.stopPrank();

        assertEq(beforeBalance + amount, _token.balanceOf(toAddress));
    }
}
