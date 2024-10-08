// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IRedeemOptimizer } from "@credbull/token/ERC1155/IRedeemOptimizer.sol";
import { RedeemOptimizer } from "@credbull/token/ERC1155/RedeemOptimizer.sol";
import { RedeemOptimizerFIFO } from "@credbull/token/ERC1155/RedeemOptimizerFIFO.sol";
import { IMultiTokenVault } from "@credbull/token/ERC1155/IMultiTokenVault.sol";

import { MultiTokenVaultTest } from "@test/src/token/ERC1155/MultiTokenVaultTest.t.sol";
import { IMTVTestParamArray } from "@test/test/token/ERC1155/IMTVTestParamArray.t.sol";

contract RedeemOptimizerFIFOTest is MultiTokenVaultTest {
    address private _owner = makeAddr("owner");
    address private _alice = makeAddr("alice");

    IMTVTestParamArray private testParamsArr;

    function setUp() public override {
        super.setUp();

        testParamsArr = new IMTVTestParamArray();
        testParamsArr.addTestParam(_testParams1);
        testParamsArr.addTestParam(_testParams2);
        testParamsArr.addTestParam(_testParams3);
    }

    function test__RedeemOptimizerTest__RedeemAllShares() public {
        uint256 assetToSharesRatio = 2;

        // setup
        IMultiTokenVault multiTokenVault = _createMultiTokenVault(_asset, assetToSharesRatio, 10);
        IRedeemOptimizer redeemOptimizer =
            new RedeemOptimizerFIFO(IRedeemOptimizer.OptimizerBasis.Shares, multiTokenVault.currentPeriodsElapsed());

        uint256[] memory depositShares = _testDepositOnly(_alice, multiTokenVault, testParamsArr.all());
        uint256 totalDepositShares = depositShares[0] + depositShares[1] + depositShares[2];

        // warp vault ahead to redeemPeriod
        uint256 redeemPeriod = _testParams3.redeemPeriod;
        _warpToPeriod(multiTokenVault, redeemPeriod);

        // check full redeem
        (uint256[] memory redeemDepositPeriods, uint256[] memory sharesAtPeriods) =
            redeemOptimizer.optimize(multiTokenVault, _alice, totalDepositShares, 0, redeemPeriod); // optimize using share basis.  assets not used

        assertEq(testParamsArr.depositPeriods(), redeemDepositPeriods, "optimizeRedeem - depositPeriods not correct");
        assertEq(depositShares, sharesAtPeriods, "optimizeRedeem - shares not correct");
    }

    function test__RedeemOptimizerTest__WithdrawAllShares() public {
        uint256 assetToSharesRatio = 2;
        uint256 redeemPeriod = _testParams3.redeemPeriod;

        // setup
        IMultiTokenVault multiTokenVault = _createMultiTokenVault(_asset, assetToSharesRatio, 10);
        IRedeemOptimizer redeemOptimizer = new RedeemOptimizerFIFO(
            IRedeemOptimizer.OptimizerBasis.AssetsWithReturns, multiTokenVault.currentPeriodsElapsed()
        );

        uint256[] memory depositShares = _testDepositOnly(_alice, multiTokenVault, testParamsArr.all());
        uint256[] memory depositAssets = multiTokenVault.convertToAssetsForDepositPeriodBatch(
            depositShares, testParamsArr.depositPeriods(), redeemPeriod
        );
        assertEq(depositShares.length, depositAssets.length, "mismatch in convertToAssets");
        uint256 totalAssets = depositAssets[0] + depositAssets[1] + depositAssets[2];

        // warp vault ahead to redeemPeriod
        _warpToPeriod(multiTokenVault, redeemPeriod);

        // check full withdraw
        (uint256[] memory withdrawDepositPeriods, uint256[] memory sharesAtPeriods) =
            redeemOptimizer.optimize(multiTokenVault, _alice, 0, totalAssets, redeemPeriod); // optimize using asset basis.  shares not used

        assertEq(testParamsArr.depositPeriods(), withdrawDepositPeriods, "optimizeRedeem - depositPeriods not correct");
        assertEq(depositShares, sharesAtPeriods, "optimizeRedeem - shares not correct");
    }

    function test__RedeemOptimizerTest__PartialRedeem() public {
        uint256 residualShareAmount = 1 * _scale; // leave 1 share after redeem
        uint256 redeemPeriod = _testParams3.redeemPeriod;

        // ---------------------- setup ----------------------
        IMultiTokenVault multiTokenVault = _createMultiTokenVault(_asset, 2, 10);
        IRedeemOptimizer redeemOptimizer = new RedeemOptimizerFIFO(
            IRedeemOptimizer.OptimizerBasis.AssetsWithReturns, multiTokenVault.currentPeriodsElapsed()
        );
        uint256[] memory depositShares = _testDepositOnly(_alice, multiTokenVault, testParamsArr.all());

        uint256 sharesToWithdraw = depositShares[0] + depositShares[1] + depositShares[2] - residualShareAmount;

        // ---------------------- redeem ----------------------
        _warpToPeriod(multiTokenVault, redeemPeriod); // warp vault ahead to redeemPeriod

        (uint256[] memory redeemDepositPeriods, uint256[] memory redeemSharesAtPeriods) =
            redeemOptimizer.optimizeRedeemShares(multiTokenVault, _alice, sharesToWithdraw, redeemPeriod);
        // verify using shares
        assertEq(depositShares[0], redeemSharesAtPeriods[0], "optimizeRedeem partial - wrong shares period 0");
        assertEq(depositShares[1], redeemSharesAtPeriods[1], "optimizeRedeem partial - wrong shares period 1");
        assertEq(
            depositShares[2] - residualShareAmount,
            redeemSharesAtPeriods[2],
            "optimizeRedeem partial - wrong shares period 2"
        ); // reduced by 1 share

        assertEq(testParamsArr.depositPeriods(), redeemDepositPeriods, "optimizeRedeem - depositPeriods not correct");
    }

    function test__RedeemOptimizerTest__PartialWithdraw() public {
        uint256 residualShareAmount = 1 * _scale; // leave 1 share after redeem
        uint256 redeemPeriod = _testParams3.redeemPeriod;

        // ---------------------- setup ----------------------
        IMultiTokenVault multiTokenVault = _createMultiTokenVault(_asset, 2, 10);
        IRedeemOptimizer redeemOptimizer = new RedeemOptimizerFIFO(
            IRedeemOptimizer.OptimizerBasis.AssetsWithReturns, multiTokenVault.currentPeriodsElapsed()
        );

        uint256[] memory depositShares = _testDepositOnly(_alice, multiTokenVault, testParamsArr.all());
        uint256[] memory depositAssets = multiTokenVault.convertToAssetsForDepositPeriodBatch(
            depositShares, testParamsArr.depositPeriods(), redeemPeriod
        );

        uint256 residualAssetAmount = multiTokenVault.convertToAssetsForDepositPeriod(
            residualShareAmount, _testParams3.depositPeriod, redeemPeriod
        );
        uint256 assetsToWithdraw = depositAssets[0] + depositAssets[1] + depositAssets[2] - residualAssetAmount;

        // ---------------------- redeem ----------------------
        _warpToPeriod(multiTokenVault, redeemPeriod); // warp vault ahead to redeemPeriod

        (uint256[] memory actualDepositPeriods, uint256[] memory actualSharesAtPeriods) =
            redeemOptimizer.optimizeWithdrawAssets(multiTokenVault, _alice, assetsToWithdraw, redeemPeriod);

        // verify using shares
        assertEq(depositShares[0], actualSharesAtPeriods[0], "optimizeWithdraw partial - wrong shares period 0");
        assertEq(depositShares[1], actualSharesAtPeriods[1], "optimizeWithdraw partial - wrong shares period 1");
        assertEq(
            depositShares[2] - residualShareAmount,
            actualSharesAtPeriods[2],
            "optimizeWithdraw partial - wrong shares period 2"
        ); // reduced by 1 share with returns

        // // verify using assets
        uint256[] memory actualAssetsAtPeriods = multiTokenVault.convertToAssetsForDepositPeriodBatch(
            actualSharesAtPeriods, actualDepositPeriods, redeemPeriod
        );

        assertEq(
            testParamsArr.depositPeriods().length,
            actualAssetsAtPeriods.length,
            "convertToAssetsForDepositPeriods partial - length incorrect"
        );
        assertEq(
            assetsToWithdraw,
            actualAssetsAtPeriods[0] + actualAssetsAtPeriods[1] + actualAssetsAtPeriods[2],
            "convertToAssetsForDepositPeriods partial - total incorrect"
        );
    }

    function test__RedeemOptimizerTest__InsufficientSharesShouldRevert() public {
        IMultiTokenVault multiTokenVault = _createMultiTokenVault(_asset, 1, 10);
        uint256 vaultCurrentPeriod = multiTokenVault.currentPeriodsElapsed();

        // no deposits - should fail
        uint256 oneShare = 1;
        IRedeemOptimizer redeemOptimizer =
            new RedeemOptimizerFIFO(IRedeemOptimizer.OptimizerBasis.Shares, vaultCurrentPeriod);
        vm.expectRevert(abi.encodeWithSelector(RedeemOptimizer.RedeemOptimizer__OptimizerFailed.selector, 0, oneShare));
        redeemOptimizer.optimizeRedeemShares(multiTokenVault, _alice, oneShare, vaultCurrentPeriod);

        // shares to find greater than the deposits
        uint256 deposit1Shares = _testDepositOnly(_alice, multiTokenVault, _testParams1);
        uint256 deposit2Shares = _testDepositOnly(_alice, multiTokenVault, _testParams2);
        uint256 totalDepositShares = deposit1Shares + deposit2Shares;

        uint256 sharesGreaterThanDeposits = totalDepositShares + 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                RedeemOptimizer.RedeemOptimizer__OptimizerFailed.selector, 0, sharesGreaterThanDeposits
            )
        );
        redeemOptimizer.optimizeRedeemShares(multiTokenVault, _alice, sharesGreaterThanDeposits, vaultCurrentPeriod);
    }
}
