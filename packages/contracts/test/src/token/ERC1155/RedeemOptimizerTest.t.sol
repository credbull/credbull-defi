// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IRedeemOptimizer } from "@credbull/token/ERC1155/IRedeemOptimizer.sol";
import { RedeemOptimizer } from "@credbull/token/ERC1155/RedeemOptimizer.sol";
import { IMultiTokenVault } from "@credbull/token/ERC1155/IMultiTokenVault.sol";

import { MultiTokenVaultTest } from "@test/src/token/ERC1155/MultiTokenVaultTest.t.sol";
import { IMTVTestParamArray } from "@test/test/token/ERC1155/IMTVTestParamArray.t.sol";

contract RedeemOptimizerTest is MultiTokenVaultTest {
    address private _owner = makeAddr("owner");
    address private _alice = makeAddr("alice");

    IMTVTestParamArray private testParamsArr;

    function setUp() public override {
        super.setUp();
    }

    function test__RedeemOptimizerTest__InvalidPeriodRangeShouldRevert() public {
        IMultiTokenVault multiTokenVault = _createMultiTokenVault(_asset, 1, 10);

        uint256 vaultCurrentPeriod = multiTokenVault.currentPeriodsElapsed();
        uint256 invalidFromDepositPeriod = vaultCurrentPeriod + 1; // from greater than to period is not allowed

        IRedeemOptimizer redeemOptimizer =
            new ExposeAssertionRedeemOptimizer(IRedeemOptimizer.OptimizerBasis.Shares, invalidFromDepositPeriod);
        vm.expectRevert(
            abi.encodeWithSelector(
                RedeemOptimizer.RedeemOptimizer__InvalidDepositPeriodRange.selector,
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

        ExposeAssertionRedeemOptimizer redeemOptimizer =
            new ExposeAssertionRedeemOptimizer(IRedeemOptimizer.OptimizerBasis.Shares, vaultCurrentPeriod);

        vm.expectRevert(
            abi.encodeWithSelector(
                RedeemOptimizer.RedeemOptimizer__FutureToDepositPeriod.selector,
                invalidToDepositPeriod,
                vaultCurrentPeriod
            )
        );
        redeemOptimizer.assertOptimization(
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
}

contract ExposeAssertionRedeemOptimizer is RedeemOptimizer {
    constructor(OptimizerBasis preferredOptimizationBasis, uint256 startDepositPeriod)
        RedeemOptimizer(preferredOptimizationBasis, startDepositPeriod)
    { }

    function assertOptimization(IMultiTokenVault vault, OptimizerParams memory optimizerParams) public view {
        _assertOptimization(vault, optimizerParams);
    }

    function _findAmount(IMultiTokenVault, /*vault*/ OptimizerParams memory /*optimizerParams*/ )
        internal
        view
        override
        returns (uint256[] memory depositPeriods, uint256[] memory sharesAtPeriods)
    {
        // Stubbed.
        return (new uint256[](0), new uint256[](0));
    }
}
