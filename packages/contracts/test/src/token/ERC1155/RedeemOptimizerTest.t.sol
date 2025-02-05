// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IRedeemOptimizer } from "@credbull/token/ERC1155/IRedeemOptimizer.sol";
import { RedeemOptimizerFIFO } from "@credbull/token/ERC1155/RedeemOptimizerFIFO.sol";
import { IMultiTokenVault } from "@credbull/token/ERC1155/IMultiTokenVault.sol";
import { IVault } from "@test/test/token/ERC4626/IVault.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { IMultiTokenVaultVerifierBase } from "@test/test/token/ERC1155/IMultiTokenVaultVerifierBase.t.sol";
import { MultiTokenVaultDailyPeriodsVerifier } from "@test/test/token/ERC1155/MultiTokenVaultDailyPeriodsVerifier.t.sol";
import { MultiTokenVaultDailyPeriods } from "@test/test/token/ERC1155/MultiTokenVaultDailyPeriods.t.sol";
import { TestParamSet } from "@test/test/token/ERC1155/TestParamSet.t.sol";

import { IVaultTestSuite } from "@test/src/token/ERC4626/IVaultTestSuite.t.sol";

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract RedeemOptimizerTest is IVaultTestSuite {
    using TestParamSet for TestParamSet.TestParam[];

    TestParamSet.TestParam[] private testParams;

    IMultiTokenVault private _multiTokenVault;
    IMultiTokenVaultVerifierBase private _multiTokenVerifier;

    function setUp() public virtual override {
        _multiTokenVault = _createMultiTokenVault(_createAsset(_owner), 3, 10);
        _multiTokenVerifier = new MultiTokenVaultDailyPeriodsVerifier();

        init(_toIVault(_multiTokenVault), _multiTokenVerifier);

        testParams.push(TestParamSet.TestParam({ principal: 500 * _scale, depositPeriod: 10, redeemPeriod: 21 }));
        testParams.push(TestParamSet.TestParam({ principal: 300 * _scale, depositPeriod: 15, redeemPeriod: 17 }));
        testParams.push(TestParamSet.TestParam({ principal: 700 * _scale, depositPeriod: 30, redeemPeriod: 55 }));
    }

    /// @dev - TODO - directly inherit from IVault with next version
    function _toIVault(IMultiTokenVault multiTokenVault) internal pure returns (IVault vault_) {
        return IVault(address(multiTokenVault));
    }

    function test__RedeemOptimizerTest__RedeemAllShares() public {
        uint256 assetToSharesRatio = 2;

        // setup
        IMultiTokenVault multiTokenVault = _createMultiTokenVault(_asset, assetToSharesRatio, 10);
        IRedeemOptimizer redeemOptimizer =
            new RedeemOptimizerFIFO(IRedeemOptimizer.OptimizerBasis.Shares, multiTokenVault.currentPeriodsElapsed());

        uint256[] memory depositShares = _multiTokenVerifier._verifyDepositOnlyBatch(
            TestParamSet.toSingletonUsers(_alice), _toIVault(multiTokenVault), testParams
        );
        uint256 totalDepositShares = depositShares[0] + depositShares[1] + depositShares[2];

        // warp vault ahead to redeemPeriod
        uint256 redeemPeriod = testParams[2].redeemPeriod;
        _multiTokenVerifier._warpToPeriod(_toIVault(multiTokenVault), redeemPeriod);

        // check full redeem
        (uint256[] memory redeemDepositPeriods, uint256[] memory sharesAtPeriods) =
            redeemOptimizer.optimize(multiTokenVault, _alice, totalDepositShares, 0, redeemPeriod); // optimize using share basis.  assets not used

        assertEq(testParams.depositPeriods(), redeemDepositPeriods, "optimizeRedeem - depositPeriods not correct");
        assertEq(depositShares, sharesAtPeriods, "optimizeRedeem - shares not correct");
    }

    function test__RedeemOptimizerTest__WithdrawAllShares() public {
        uint256 assetToSharesRatio = 2;
        uint256 redeemPeriod = testParams[2].redeemPeriod;

        // setup
        IMultiTokenVault multiTokenVault = _createMultiTokenVault(_asset, assetToSharesRatio, 10);
        IRedeemOptimizer redeemOptimizer = new RedeemOptimizerFIFO(
            IRedeemOptimizer.OptimizerBasis.AssetsWithReturns, multiTokenVault.currentPeriodsElapsed()
        );

        uint256[] memory depositShares = _multiTokenVerifier._verifyDepositOnlyBatch(
            TestParamSet.toSingletonUsers(_alice), _toIVault(multiTokenVault), testParams
        );
        uint256[] memory depositAssets = multiTokenVault.convertToAssetsForDepositPeriodBatch(
            depositShares, testParams.depositPeriods(), redeemPeriod
        );
        assertEq(depositShares.length, depositAssets.length, "mismatch in convertToAssets");
        uint256 totalAssets = depositAssets[0] + depositAssets[1] + depositAssets[2];

        // warp vault ahead to redeemPeriod
        _multiTokenVerifier._warpToPeriod(_toIVault(multiTokenVault), redeemPeriod);

        // check full withdraw
        (uint256[] memory withdrawDepositPeriods, uint256[] memory sharesAtPeriods) =
            redeemOptimizer.optimize(multiTokenVault, _alice, 0, totalAssets, redeemPeriod); // optimize using asset basis.  shares not used

        assertEq(testParams.depositPeriods(), withdrawDepositPeriods, "optimizeRedeem - depositPeriods not correct");
        assertEq(depositShares, sharesAtPeriods, "optimizeRedeem - shares not correct");
    }

    function test__RedeemOptimizerTest__PartialRedeem() public {
        uint256 residualShareAmount = 1 * _scale; // leave 1 share after redeem
        uint256 redeemPeriod = testParams[2].redeemPeriod;

        // ---------------------- setup ----------------------
        IMultiTokenVault multiTokenVault = _createMultiTokenVault(_asset, 2, 10);
        IRedeemOptimizer redeemOptimizer = new RedeemOptimizerFIFO(
            IRedeemOptimizer.OptimizerBasis.AssetsWithReturns, multiTokenVault.currentPeriodsElapsed()
        );
        uint256[] memory depositShares = _multiTokenVerifier._verifyDepositOnlyBatch(
            TestParamSet.toSingletonUsers(_alice), _toIVault(multiTokenVault), testParams
        );

        uint256 sharesToWithdraw = depositShares[0] + depositShares[1] + depositShares[2] - residualShareAmount;

        // ---------------------- redeem ----------------------
        _multiTokenVerifier._warpToPeriod(_toIVault(multiTokenVault), redeemPeriod); // warp vault ahead to redeemPeriod

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

        assertEq(testParams.depositPeriods(), redeemDepositPeriods, "optimizeRedeem - depositPeriods not correct");
    }

    function test__RedeemOptimizerTest__PartialWithdraw() public {
        uint256 residualShareAmount = 1 * _scale; // leave 1 share after redeem
        uint256 redeemPeriod = testParams[2].redeemPeriod;

        // ---------------------- setup ----------------------
        IMultiTokenVault multiTokenVault = _createMultiTokenVault(_asset, 2, 10);
        IRedeemOptimizer redeemOptimizer = new RedeemOptimizerFIFO(
            IRedeemOptimizer.OptimizerBasis.AssetsWithReturns, multiTokenVault.currentPeriodsElapsed()
        );

        uint256[] memory depositShares = _multiTokenVerifier._verifyDepositOnlyBatch(
            TestParamSet.toSingletonUsers(_alice), _toIVault(multiTokenVault), testParams
        );
        uint256[] memory depositAssets = multiTokenVault.convertToAssetsForDepositPeriodBatch(
            depositShares, testParams.depositPeriods(), redeemPeriod
        );

        uint256 residualAssetAmount = multiTokenVault.convertToAssetsForDepositPeriod(
            residualShareAmount, testParams[2].depositPeriod, redeemPeriod
        );
        uint256 assetsToWithdraw = depositAssets[0] + depositAssets[1] + depositAssets[2] - residualAssetAmount;

        // ---------------------- redeem ----------------------
        _multiTokenVerifier._warpToPeriod(_toIVault(multiTokenVault), redeemPeriod); // warp vault ahead to redeemPeriod

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
            testParams.depositPeriods().length,
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
        vm.expectRevert(
            abi.encodeWithSelector(RedeemOptimizerFIFO.RedeemOptimizer__OptimizerFailed.selector, 0, oneShare)
        );
        redeemOptimizer.optimizeRedeemShares(multiTokenVault, _alice, oneShare, vaultCurrentPeriod);

        (TestParamSet.TestUsers memory depositUsers,) = _multiTokenVerifier._createTestUsers(_alice);

        // shares to find greater than the deposits
        uint256 deposit1Shares =
            _multiTokenVerifier._verifyDepositOnly(depositUsers, _toIVault(multiTokenVault), testParams[0]);
        uint256 deposit2Shares =
            _multiTokenVerifier._verifyDepositOnly(depositUsers, _toIVault(multiTokenVault), testParams[1]);
        uint256 totalDepositShares = deposit1Shares + deposit2Shares;

        uint256 sharesGreaterThanDeposits = totalDepositShares + 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                RedeemOptimizerFIFO.RedeemOptimizer__OptimizerFailed.selector, 0, sharesGreaterThanDeposits
            )
        );
        redeemOptimizer.optimizeRedeemShares(multiTokenVault, _alice, sharesGreaterThanDeposits, vaultCurrentPeriod);
    }

    function test__RedeemOptimizerTest__InvalidPeriodRangeShouldRevert() public {
        IMultiTokenVault multiTokenVault = _createMultiTokenVault(_asset, 1, 10);

        uint256 vaultCurrentPeriod = multiTokenVault.currentPeriodsElapsed();
        uint256 invalidFromDepositPeriod = vaultCurrentPeriod + 1; // from greater than to period is not allowed

        IRedeemOptimizer redeemOptimizer =
            new RedeemOptimizerFIFO(IRedeemOptimizer.OptimizerBasis.Shares, invalidFromDepositPeriod);
        vm.expectRevert(
            abi.encodeWithSelector(
                RedeemOptimizerFIFO.RedeemOptimizer__InvalidDepositPeriodRange.selector,
                invalidFromDepositPeriod,
                vaultCurrentPeriod
            )
        );
        redeemOptimizer.optimizeRedeemShares(multiTokenVault, _alice, 1, vaultCurrentPeriod);
    }

    function test__RedeemOptimizerTest__FutureToPeriodShouldRevert() public {
        IMultiTokenVault multiTokenVault = _createMultiTokenVault(_asset, 1, 10);

        uint256 vaultCurrentPeriod = multiTokenVault.currentPeriodsElapsed();
        uint256 invalidToDepositPeriod = vaultCurrentPeriod + 1; // future to period is not allowed

        RedeemOptimizerFIFOMock redeemOptimizerMock =
            new RedeemOptimizerFIFOMock(IRedeemOptimizer.OptimizerBasis.Shares, vaultCurrentPeriod);

        vm.expectRevert(
            abi.encodeWithSelector(
                RedeemOptimizerFIFO.RedeemOptimizer__FutureToDepositPeriod.selector,
                invalidToDepositPeriod,
                vaultCurrentPeriod
            )
        );
        redeemOptimizerMock.findAmount(
            multiTokenVault,
            IRedeemOptimizer.OptimizerParams({
                owner: _owner,
                amountToFind: 1,
                fromDepositPeriod: vaultCurrentPeriod,
                toDepositPeriod: invalidToDepositPeriod,
                redeemPeriod: vaultCurrentPeriod,
                optimizerBasis: IRedeemOptimizer.OptimizerBasis.Shares
            })
        );
    }

    function _createMultiTokenVault(IERC20Metadata asset_, uint256 assetToSharesRatio, uint256 yieldPercentage)
        internal
        returns (IMultiTokenVault)
    {
        MultiTokenVaultDailyPeriods vaultImpl = new MultiTokenVaultDailyPeriods();
        return MultiTokenVaultDailyPeriods(
            address(
                new ERC1967Proxy(
                    address(vaultImpl),
                    abi.encodeWithSelector(vaultImpl.initialize.selector, asset_, assetToSharesRatio, yieldPercentage)
                )
            )
        );
    }
}

contract RedeemOptimizerFIFOMock is RedeemOptimizerFIFO {
    constructor(OptimizerBasis preferredOptimizationBasis, uint256 startDepositPeriod)
        RedeemOptimizerFIFO(preferredOptimizationBasis, startDepositPeriod)
    { }

    function findAmount(IMultiTokenVault vault, OptimizerParams memory params)
        public
        view
        returns (uint256[] memory depositPeriods, uint256[] memory sharesAtPeriods)
    {
        return _findAmount(vault, params);
    }
}
