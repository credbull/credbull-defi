// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IMultiTokenVault } from "@credbull/token/ERC1155/IMultiTokenVault.sol";
import { IVault } from "@credbull/token/ERC4626/IVault.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IVaultVerifierBase } from "@test/test/token/ERC4626/IVaultVerifierBase.t.sol";
import { TestParamSet } from "@test/test/token/ERC1155/TestParamSet.t.sol";

abstract contract IMultiTokenVaultVerifierBase is IVaultVerifierBase {
    using TestParamSet for TestParamSet.TestParam[];

    /// @dev test the vault at the given test parameters
    function verifyVault(
        TestParamSet.TestUsers memory depositUsers,
        TestParamSet.TestUsers memory redeemUsers,
        IVault vault,
        TestParamSet.TestParam[] memory testParams
    ) public override returns (uint256[] memory sharesAtPeriods_, uint256[] memory assetsAtPeriods_) {
        IMultiTokenVault multiTokenVault = IMultiTokenVault(address(vault));

        // previews okay to test individually.  don't update vault state.
        for (uint256 i = 0; i < testParams.length; i++) {
            TestParamSet.TestParam memory testParam = testParams[i];
            _testConvertToAssetAndSharesAtPeriod(multiTokenVault, testParam); // previews only, account agnostic
            _testPreviewDepositAndPreviewRedeem(multiTokenVault, testParam); // previews only, account agnostic
        }

        // capture vault state before warping around
        uint256 prevVaultPeriodsElapsed = vault.currentPeriodsElapsed();

        // ------------------- deposits w/ redeems per deposit -------------------
        (sharesAtPeriods_, assetsAtPeriods_) = super.verifyVault(depositUsers, redeemUsers, vault, testParams);

        // ------------------- deposits w/ redeems across multiple deposits -------------------
        _testVaultCombineDepositsForRedeem(depositUsers, redeemUsers, multiTokenVault, testParams, 2);

        _warpToPeriod(vault, prevVaultPeriodsElapsed); // restore previous period state
    }

    /// @dev test the vault deposits and redeems across multiple deposit periods
    function _testVaultCombineDepositsForRedeem(
        TestParamSet.TestUsers memory depositUsers,
        TestParamSet.TestUsers memory redeemUsers,
        IMultiTokenVault vault,
        TestParamSet.TestParam[] memory testParams,
        uint256 splitBefore
    ) internal returns (uint256[] memory sharesAtPeriods_, uint256 assetsAtPeriods1_, uint256 assetsAtPeriods2_) {
        // NB - test all of the deposits BEFORE redeems.  verifies no side-effects from deposits when redeeming.
        uint256[] memory sharesAtPeriods = _verifyDepositOnly(depositUsers, vault, testParams);

        // NB - test all of the redeems AFTER deposits.  verifies no side-effects from deposits when redeeming.
        uint256 finalRedeemPeriod = testParams.latestRedeemPeriod();

        // split into two batches
        (TestParamSet.TestParam[] memory redeemParams1, TestParamSet.TestParam[] memory redeemParams2) =
            testParams._splitBefore(splitBefore);

        assertLe(2, redeemParams1.length, "redeem params array 1 should have multiple params");
        assertLe(2, redeemParams2.length, "redeem params array 2 should have multiple params");

        uint256 partialRedeemPeriod = finalRedeemPeriod - 2;

        uint256 assetsAtPeriods1 = _testRedeemMultiDeposit(redeemUsers, vault, redeemParams1, partialRedeemPeriod);
        uint256 assetsAtPeriods2 = _testRedeemMultiDeposit(redeemUsers, vault, redeemParams2, finalRedeemPeriod);

        return (sharesAtPeriods, assetsAtPeriods1, assetsAtPeriods2);
    }

    /// @dev verify convertToAssets and convertToShares.  These are a "preview" and do NOT update vault assets or shares.
    function _testConvertToAssetAndSharesAtPeriod(IMultiTokenVault vault, TestParamSet.TestParam memory testParam)
        internal
        virtual
        returns (uint256 actualSharesAtPeriod, uint256 actualAssetsAtPeriod)
    {
        uint256 prevVaultPeriodsElapsed = vault.currentPeriodsElapsed(); // save previous state for later

        // ------------------- check toShares/toAssets - specified period -------------------
        actualSharesAtPeriod = vault.convertToSharesForDepositPeriod(testParam.principal, testParam.depositPeriod);
        assertApproxEqAbs(
            _expectedShares(vault, testParam),
            actualSharesAtPeriod,
            TOLERANCE,
            _assertMsg(
                "convertToSharesForDepositPeriod shares don't match expected shares", vault, testParam.depositPeriod
            )
        );

        actualAssetsAtPeriod =
            vault.convertToAssetsForDepositPeriod(actualSharesAtPeriod, testParam.depositPeriod, testParam.redeemPeriod);

        uint256 expectedAssetsAtRedeem = testParam.principal + _expectedReturns(vault, testParam);

        assertApproxEqAbs(
            expectedAssetsAtRedeem,
            actualAssetsAtPeriod,
            TOLERANCE,
            _assertMsg("yield does not equal principal + interest", vault, testParam.depositPeriod)
        );

        // ------------------- check toShares/toAssets - current period -------------------
        _warpToPeriod(vault, testParam.depositPeriod); // warp to deposit
        uint256 actualShares = vault.convertToShares(testParam.principal);

        _warpToPeriod(vault, testParam.redeemPeriod); // warp to redeem
        assertApproxEqAbs(
            expectedAssetsAtRedeem,
            vault.convertToAssetsForDepositPeriod(actualShares, testParam.depositPeriod),
            TOLERANCE,
            _assertMsg("toShares/toAssets yield does not equal principal + interest", vault, testParam.depositPeriod)
        );

        _warpToPeriod(vault, prevVaultPeriodsElapsed); // restore to previous state

        return (actualAssetsAtPeriod, actualAssetsAtPeriod);
    }

    /// @dev verify previewDeposit and previewRedeem.  These are a "preview" and do NOT update vault assets or shares.
    function _testPreviewDepositAndPreviewRedeem(IMultiTokenVault vault, TestParamSet.TestParam memory testParam)
        internal
        virtual
        returns (uint256 actualSharesAtPeriod, uint256 actualAssetsAtPeriod)
    {
        uint256 prevVaultPeriodsElapsed = vault.currentPeriodsElapsed();

        // ------------------- check previewDeposit/previewRedeem - current period -------------------
        _warpToPeriod(vault, testParam.depositPeriod); // warp to deposit
        actualSharesAtPeriod = vault.previewDeposit(testParam.principal);
        assertApproxEqAbs(
            _expectedShares(vault, testParam),
            actualSharesAtPeriod,
            TOLERANCE,
            _assertMsg("previewDeposit shares don't match expected shares", vault, testParam.depositPeriod)
        );

        _warpToPeriod(vault, testParam.redeemPeriod); // warp to redeem / withdraw
        actualAssetsAtPeriod = vault.previewRedeemForDepositPeriod(actualSharesAtPeriod, testParam.depositPeriod);

        uint256 expectedAssetsAtRedeem = testParam.principal + _expectedReturns(vault, testParam);

        // check previewRedeem
        assertApproxEqAbs(
            expectedAssetsAtRedeem,
            actualAssetsAtPeriod,
            TOLERANCE,
            _assertMsg(
                "previewDeposit/previewRedeem yield does not equal principal + interest", vault, testParam.depositPeriod
            )
        );

        _warpToPeriod(vault, prevVaultPeriodsElapsed); // restore previous period state

        return (actualSharesAtPeriod, actualAssetsAtPeriod);
    }

    /// @dev - requestRedeem over multiple deposit and principals into one requestRedeemPeriod
    function _testRedeemMultiDeposit(
        TestParamSet.TestUsers memory redeemUsers,
        IMultiTokenVault vault,
        TestParamSet.TestParam[] memory depositTestParams,
        uint256 redeemPeriod // we are testing multiple deposits into one redeemPeriod
    ) internal virtual returns (uint256 assets_) {
        _warpToPeriod(vault, redeemPeriod);

        IERC20 asset = IERC20(vault.asset());

        uint256 prevAssetBalance = asset.balanceOf(redeemUsers.tokenReceiver);
        uint256[] memory prevSharesBalance = vault.balanceOfBatch(
            depositTestParams.accountArray(redeemUsers.tokenOwner), depositTestParams.depositPeriods()
        );

        // get the vault enough to cover redeems
        _transferFromTokenOwner(asset, address(vault), depositTestParams.totalPrincipal()); // this will give the vault 2x principal

        uint256 assets = _vaultRedeemBatch(redeemUsers, vault, depositTestParams, redeemPeriod);

        assertEq(
            prevAssetBalance + assets,
            asset.balanceOf(redeemUsers.tokenReceiver),
            "receiver did not receive assets - redeem on multi deposit"
        );

        // check share balances reduced on the owner
        uint256[] memory sharesBalance = vault.balanceOfBatch(
            depositTestParams.accountArray(redeemUsers.tokenOwner), depositTestParams.depositPeriods()
        );

        assertEq(prevSharesBalance.length, sharesBalance.length, "mismatch on share balance");

        for (uint256 i = 0; i < prevSharesBalance.length; ++i) {
            uint256 sharesAtPeriod = vault.convertToSharesForDepositPeriod(
                depositTestParams[i].principal, depositTestParams[i].depositPeriod
            );
            assertEq(prevSharesBalance[i] - sharesAtPeriod, sharesBalance[i], "token owner shares balance incorrect");
        }

        return assets;
    }

    /// @dev vault redeem across multiple deposit periods. (if supported)
    function _vaultRedeemBatch(
        TestParamSet.TestUsers memory redeemUsers,
        IMultiTokenVault vault,
        TestParamSet.TestParam[] memory depositTestParams,
        uint256 redeemPeriod
    ) internal virtual returns (uint256 assets_) {
        _warpToPeriod(vault, redeemPeriod); // warp the vault to redeem period

        // authorize the tokenOperator
        vm.prank(redeemUsers.tokenOwner);
        vault.setApprovalForAll(redeemUsers.tokenOperator, true);

        uint256 assets = 0;
        vm.startPrank(redeemUsers.tokenOperator);
        // IMultiTokenVault doesn't support redeeming across deposit periods.  redeem period by period instead.
        for (uint256 i = 0; i < depositTestParams.length; ++i) {
            uint256 depositPeriod = depositTestParams[i].depositPeriod;
            uint256 sharesAtPeriod =
                vault.convertToSharesForDepositPeriod(depositTestParams[i].principal, depositPeriod);

            assets += vault.redeemForDepositPeriod(
                sharesAtPeriod, redeemUsers.tokenReceiver, redeemUsers.tokenOwner, depositTestParams[i].depositPeriod
            );
        }
        vm.stopPrank();

        // de-authorize the tokenOperator
        vm.prank(redeemUsers.tokenOwner);
        vault.setApprovalForAll(redeemUsers.tokenOperator, false);

        return assets;
    }

    /// @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
    // function setApprovalForAll(address operator, bool approved) external;
    function _approveForAll(IVault vault, address owner, address operator, bool approved) internal virtual override {
        IMultiTokenVault multiTokenVault = IMultiTokenVault(address(vault));

        vm.prank(owner);
        multiTokenVault.setApprovalForAll(operator, approved);
    }
}
