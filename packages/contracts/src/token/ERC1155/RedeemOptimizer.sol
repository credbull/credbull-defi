// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IMultiTokenVault } from "@credbull/token/ERC1155/IMultiTokenVault.sol";
import { IRedeemOptimizer } from "@credbull/token/ERC1155/IRedeemOptimizer.sol";

/**
 * @title RedeemOptimizer
 * @dev Provides Optimizes the redemption of shares using a FIFO strategy.
 */
abstract contract RedeemOptimizer is IRedeemOptimizer {
    error RedeemOptimizer__InvalidDepositPeriodRange(uint256 fromPeriod, uint256 toPeriod);
    error RedeemOptimizer__FutureToDepositPeriod(uint256 toPeriod, uint256 currentPeriod);
    error RedeemOptimizer__OptimizerFailed(uint256 amountFound, uint256 amountToFind);

    OptimizerBasis public immutable DEFAULT_BASIS;
    uint256 private _startDepositPeriod;

    constructor(OptimizerBasis defaultBasis, uint256 startDepositPeriod) {
        DEFAULT_BASIS = defaultBasis;
        _startDepositPeriod = startDepositPeriod;
    }

    /// @inheritdoc IRedeemOptimizer
    function optimize(IMultiTokenVault vault, address owner, uint256 shares, uint256 assets, uint256 redeemPeriod)
        public
        virtual
        returns (uint256[] memory depositPeriods_, uint256[] memory sharesAtPeriods_)
    {
        return OptimizerBasis.AssetsWithReturns == DEFAULT_BASIS
            ? optimizeWithdrawAssets(vault, owner, assets, redeemPeriod)
            : optimizeRedeemShares(vault, owner, shares, redeemPeriod);
    }

    /// @inheritdoc IRedeemOptimizer
    function optimizeRedeemShares(IMultiTokenVault vault, address owner, uint256 shares, uint256 redeemPeriod)
        public
        virtual
        returns (uint256[] memory depositPeriods_, uint256[] memory sharesAtPeriods_)
    {
        OptimizerParams memory optimizerParams = OptimizerParams({
            owner: owner,
            amountToFind: shares,
            fromDepositPeriod: _earliestPeriodWithDeposit(vault),
            toDepositPeriod: vault.currentPeriodsElapsed(),
            redeemPeriod: redeemPeriod,
            optimizerBasis: OptimizerBasis.Shares
        });
        _assertOptimization(vault, optimizerParams);
        return _findAmount(vault, optimizerParams);
    }

    /// @inheritdoc IRedeemOptimizer
    /// @dev - assets include deposit (principal) and any returns up to the redeem period
    function optimizeWithdrawAssets(IMultiTokenVault vault, address owner, uint256 assets, uint256 redeemPeriod)
        public
        virtual
        returns (uint256[] memory depositPeriods, uint256[] memory sharesAtPeriods)
    {
        OptimizerParams memory optimizerParams = OptimizerParams({
            owner: owner,
            amountToFind: assets,
            fromDepositPeriod: _earliestPeriodWithDeposit(vault),
            toDepositPeriod: vault.currentPeriodsElapsed(),
            redeemPeriod: redeemPeriod,
            optimizerBasis: OptimizerBasis.AssetsWithReturns
        });
        _assertOptimization(vault, optimizerParams);
        return _findAmount(vault, optimizerParams);
    }

    /**
     * @notice Execute checks against the parameters to verify that the optimization is possible.
     *
     * @param vault The [IMultiTokenVault] to query.
     * @param optimizerParams The [OptimizerParams] governing the optimization.
     */
    function _assertOptimization(IMultiTokenVault vault, OptimizerParams memory optimizerParams)
        internal
        view
        virtual
    {
        if (optimizerParams.fromDepositPeriod > optimizerParams.toDepositPeriod) {
            revert RedeemOptimizer__InvalidDepositPeriodRange(
                optimizerParams.fromDepositPeriod, optimizerParams.toDepositPeriod
            );
        }

        if (optimizerParams.toDepositPeriod > vault.currentPeriodsElapsed()) {
            revert RedeemOptimizer__FutureToDepositPeriod(
                optimizerParams.toDepositPeriod, vault.currentPeriodsElapsed()
            );
        }

        // NOTE (JL,2024-10-08): Why no `redeemPeriod` checks?
    }

    /**
     * @notice Returns deposit periods and corresponding shares amounts according to the `optimizerParams` and the
     *  realisation strategy.
     * @dev Queries the vault and processes the data according to the realised strategy to determine AN optimial
     *  arrangement of Deposit Period and associated Share Amounts to satisfy the redeem requirement.
     *
     * @param vault The [IMultiTokenVault] to query.
     * @param optimizerParams The [OptimizerParams] governing the optimization.
     * @return depositPeriods The result array of Deposit Periods.
     * @return sharesAtPeriods The result array of Share Amounts.
     */
    function _findAmount(IMultiTokenVault vault, OptimizerParams memory optimizerParams)
        internal
        view
        virtual
        returns (uint256[] memory depositPeriods, uint256[] memory sharesAtPeriods);

    /**
     * @notice Determines the earliest Deposit Period at which there are deposits.
     * @dev Queries the `vault` to find the earliest Deposit Period at which there are deposits. Sets this value as
     *  `_startDepositPeriod`, the starting point for the optimizer and returns the same value.
     * @return _startDepositPeriod The earliest Deposit Period at which there are deposits.
     */
    function _earliestPeriodWithDeposit(IMultiTokenVault vault) internal virtual returns (uint256) {
        for (uint256 period = _startDepositPeriod; period <= vault.currentPeriodsElapsed(); ++period) {
            if (vault.exists(period)) {
                _startDepositPeriod = period;
                break;
            }
        }
        return _startDepositPeriod;
    }

    /**
     * @notice Utility function that trims the specified arrays to the specified size.
     * @dev Allocates 2 arrays of size `toSize` and copies the `array1` and `array2` elements to their corresponding
     *  trimmed version. Assumes that the parameter arrays are at least as large as `toSize`.
     *
     * @param toSize The size to trim the arrays to.
     * @param toTrim1 The first array to trim.
     * @param toTrim2 The second array to trim.
     * @return trimmed1 The trimmed version of `array1`.
     * @return trimmed2 The trimmed version of `array2`.
     */
    function _trimToSize(uint256 toSize, uint256[] memory toTrim1, uint256[] memory toTrim2)
        internal
        pure
        virtual
        returns (uint256[] memory trimmed1, uint256[] memory trimmed2)
    {
        trimmed1 = new uint256[](toSize);
        trimmed2 = new uint256[](toSize);
        for (uint256 i = 0; i < toSize; i++) {
            trimmed1[i] = toTrim1[i];
            trimmed2[i] = toTrim2[i];
        }
    }
}
