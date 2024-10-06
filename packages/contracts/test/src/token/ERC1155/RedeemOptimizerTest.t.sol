// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IRedeemOptimizer } from "@credbull/token/ERC1155/IRedeemOptimizer.sol";
import { RedeemOptimizerFIFO } from "@credbull/token/ERC1155/RedeemOptimizerFIFO.sol";
import { IMultiTokenVault } from "@credbull/token/ERC1155/IMultiTokenVault.sol";

import { MultiTokenVaultTest } from "@test/src/token/ERC1155/MultiTokenVaultTest.t.sol";
import { IMTVTestParamArray } from "@test/test/token/ERC1155/IMTVTestParamArray.t.sol";

contract RedeemOptimizerTest is MultiTokenVaultTest {
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
        IRedeemOptimizer redeemOptimizer = new RedeemOptimizerFIFO(multiTokenVault.currentPeriodsElapsed());

        uint256[] memory depositShares = _testDepositOnly(_alice, multiTokenVault, testParamsArr.all());
        uint256 totalDepositShares = depositShares[0] + depositShares[1] + depositShares[2];

        // warp vault ahead to redeemPeriod
        uint256 redeemPeriod = _testParams3.redeemPeriod;
        _warpToPeriod(multiTokenVault, redeemPeriod);

        // check full redeem
        (uint256[] memory redeemDepositPeriods, uint256[] memory sharesAtPeriods) =
            redeemOptimizer.optimizeRedeemShares(multiTokenVault, _alice, totalDepositShares, redeemPeriod);

        assertEq(testParamsArr.depositPeriods(), redeemDepositPeriods, "optimizeRedeem - depositPeriods not correct");
        assertEq(depositShares, sharesAtPeriods, "optimizeRedeem - shares not correct");
    }

    function test__RedeemOptimizerTest__WithdrawAllShares() public {
        uint256 assetToSharesRatio = 2;
        uint256 redeemPeriod = _testParams3.redeemPeriod;

        // setup
        IMultiTokenVault multiTokenVault = _createMultiTokenVault(_asset, assetToSharesRatio, 10);
        IRedeemOptimizer redeemOptimizer = new RedeemOptimizerFIFO(multiTokenVault.currentPeriodsElapsed());

        uint256[] memory depositShares = _testDepositOnly(_alice, multiTokenVault, testParamsArr.all());
        uint256[] memory depositAssets = multiTokenVault.convertToAssetsForDepositPeriods(
            depositShares, testParamsArr.depositPeriods(), redeemPeriod
        );
        assertEq(depositShares.length, depositAssets.length, "mismatch in convertToAssets");
        uint256 totalAssets = depositAssets[0] + depositAssets[1] + depositAssets[2];

        // warp vault ahead to redeemPeriod
        _warpToPeriod(multiTokenVault, redeemPeriod);

        // check full withdraw
        (uint256[] memory withdrawDepositPeriods, uint256[] memory sharesAtPeriods) =
            redeemOptimizer.optimizeWithdrawAssets(multiTokenVault, _alice, totalAssets, redeemPeriod);

        assertEq(testParamsArr.depositPeriods(), withdrawDepositPeriods, "optimizeRedeem - depositPeriods not correct");
        assertEq(depositShares, sharesAtPeriods, "optimizeRedeem - shares not correct");
    }

    function test__RedeemOptimizerTest__PartialWithdraw() public {
        uint256 assetToSharesRatio = 2;
        uint256 redeemPeriod = _testParams3.redeemPeriod;

        // ---------------------- setup ----------------------
        IMultiTokenVault multiTokenVault = _createMultiTokenVault(_asset, assetToSharesRatio, 10);
        IRedeemOptimizer redeemOptimizer = new RedeemOptimizerFIFO(multiTokenVault.currentPeriodsElapsed());

        uint256[] memory depositShares = _testDepositOnly(_alice, multiTokenVault, testParamsArr.all());
        uint256[] memory depositAssets = multiTokenVault.convertToAssetsForDepositPeriods(
            depositShares, testParamsArr.depositPeriods(), redeemPeriod
        );
        assertEq(depositShares.length, depositAssets.length, "mismatch in convertToAssets");
        uint256 totalAssets = depositAssets[0] + depositAssets[1] + depositAssets[2];

        assertEq(
            (_testParams1.principal + _testParams2.principal + _testParams3.principal) / 2,
            depositShares[0] + depositShares[1] + depositShares[2],
            "shares are wrong"
        );

        uint256 oneAssetWithReturns = multiTokenVault.convertToAssetsForDepositPeriod(
            1 * _scale / assetToSharesRatio, _testParams3.depositPeriod, redeemPeriod
        );
        uint256 assetsToWithdraw = totalAssets - oneAssetWithReturns;

        // ---------------------- redeem ----------------------
        _warpToPeriod(multiTokenVault, redeemPeriod); // warp vault ahead to redeemPeriod

        (uint256[] memory actualDepositPeriods, uint256[] memory actualSharesAtPeriods) =
            redeemOptimizer.optimizeWithdrawAssets(multiTokenVault, _alice, assetsToWithdraw, redeemPeriod);

        // first two periods should be fully withdrawn - third period should be partial
        assertEq(depositShares[0], actualSharesAtPeriods[0], "optimizeRedeem - wrong shares 0");
        assertEq(depositShares[1], actualSharesAtPeriods[1], "optimizeRedeem - wrong shares 1");
        // TODO - add check in for partial, should be full amount - equivalent of one asset

        // convert shares to asset equivalent for further validation
        uint256[] memory actualAssetsAtPeriods =
            multiTokenVault.convertToAssetsForDepositPeriods(actualSharesAtPeriods, actualDepositPeriods, redeemPeriod);
        assertEq(
            testParamsArr.depositPeriods().length,
            actualAssetsAtPeriods.length,
            "convertToAssetsForDepositPeriods (partial)  - length incorrect"
        );
        assertEq(
            assetsToWithdraw,
            actualAssetsAtPeriods[0] + actualAssetsAtPeriods[1] + actualAssetsAtPeriods[2],
            "convertToAssetsForDepositPeriods (partial)  - total incorrect"
        );
    }

    function test__RedeemOptimizerTest__InsufficientSharesShouldRevert() public {
        IMultiTokenVault multiTokenVault = _createMultiTokenVault(_asset, 1, 10);
        uint256 vaultCurrentPeriod = multiTokenVault.currentPeriodsElapsed();

        // no deposits - should fail
        uint256 oneShare = 1;
        IRedeemOptimizer redeemOptimizer = new RedeemOptimizerFIFO(vaultCurrentPeriod);
        vm.expectRevert(
            abi.encodeWithSelector(RedeemOptimizerFIFO.RedeemOptimizer__OptimizerFailed.selector, 0, oneShare)
        );
        redeemOptimizer.optimizeRedeemShares(multiTokenVault, _alice, oneShare, vaultCurrentPeriod);

        // shares to find greater than the deposits
        uint256 deposit1Shares = _testDepositOnly(_alice, multiTokenVault, _testParams1);
        uint256 deposit2Shares = _testDepositOnly(_alice, multiTokenVault, _testParams2);
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

        IRedeemOptimizer redeemOptimizer = new RedeemOptimizerFIFO(invalidFromDepositPeriod);
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

        RedeemOptimizerFIFOMock redeemOptimizerMock = new RedeemOptimizerFIFOMock(vaultCurrentPeriod);

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
                amountType: IRedeemOptimizer.AmountType.Shares
            })
        );
    }
}

contract RedeemOptimizerFIFOMock is RedeemOptimizerFIFO {
    constructor(uint256 startDepositPeriod) RedeemOptimizerFIFO(startDepositPeriod) { }

    function findAmount(IMultiTokenVault vault, OptimizerParams memory params)
        public
        view
        returns (uint256[] memory depositPeriods, uint256[] memory sharesAtPeriods)
    {
        return _findAmount(vault, params);
    }
}
