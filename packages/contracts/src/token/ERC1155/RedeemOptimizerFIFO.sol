// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IMultiTokenVault } from "@credbull/token/ERC1155/IMultiTokenVault.sol";
import { IRedeemOptimizer } from "@credbull/token/ERC1155/IRedeemOptimizer.sol";

/**
 * @title RedeemOptimizerFIFO
 * @dev Optimizes the redemption of shares using a FIFO strategy.
 */
contract RedeemOptimizerFIFO is IRedeemOptimizer {
    error RedeemOptimizer__InvalidDepositPeriodRange(uint256 fromPeriod, uint256 toPeriod);
    error RedeemOptimizer__FutureToDepositPeriod(uint256 toPeriod, uint256 currentPeriod);
    error RedeemOptimizer__OptimizerFailed(uint256 amountFound, uint256 amountToFind);

    uint256 public immutable START_DEPOSIT_PERIOD;

    constructor(uint256 startDepositPeriod) {
        START_DEPOSIT_PERIOD = startDepositPeriod;
    }

    /// @inheritdoc IRedeemOptimizer
    function optimizeRedeemShares(IMultiTokenVault vault, address owner, uint256 shares, uint256 redeemPeriod)
        public
        view
        returns (uint256[] memory depositPeriods_, uint256[] memory sharesAtPeriods_)
    {
        return _findAmount(
            vault,
            OptimizerParams({
                owner: owner,
                amountToFind: shares,
                fromDepositPeriod: START_DEPOSIT_PERIOD,
                toDepositPeriod: vault.currentPeriodsElapsed(),
                redeemPeriod: redeemPeriod,
                amountType: AmountType.Shares
            })
        );
    }

    /// @inheritdoc IRedeemOptimizer
    /// @dev - assets include deposit (principal) and any returns up to the redeem period
    function optimizeWithdrawAssets(IMultiTokenVault vault, address owner, uint256 assets, uint256 redeemPeriod)
        public
        view
        returns (uint256[] memory depositPeriods, uint256[] memory sharesAtPeriods)
    {
        return _findAmount(
            vault,
            OptimizerParams({
                owner: owner,
                amountToFind: assets,
                fromDepositPeriod: START_DEPOSIT_PERIOD,
                toDepositPeriod: vault.currentPeriodsElapsed(),
                redeemPeriod: redeemPeriod,
                amountType: AmountType.AssetsWithReturns
            })
        );
    }

    /// @notice Returns deposit periods and corresponding amounts (shares or assets) within the specified range.
    function _findAmount(IMultiTokenVault vault, OptimizerParams memory params)
        internal
        view
        returns (uint256[] memory depositPeriods, uint256[] memory sharesAtPeriods)
    {
        if (params.fromDepositPeriod > params.toDepositPeriod) {
            revert RedeemOptimizer__InvalidDepositPeriodRange(params.fromDepositPeriod, params.toDepositPeriod);
        }

        if (params.toDepositPeriod > vault.currentPeriodsElapsed()) {
            revert RedeemOptimizer__FutureToDepositPeriod(params.toDepositPeriod, vault.currentPeriodsElapsed());
        }

        // Create local caching arrays that can contain the maximum number of results.
        uint256[] memory cacheDepositPeriods = new uint256[]((params.toDepositPeriod - params.fromDepositPeriod) + 1);
        uint256[] memory cacheSharesAtPeriods = new uint256[]((params.toDepositPeriod - params.fromDepositPeriod) + 1);

        uint256 arrayIndex = 0;
        uint256 amountFound = 0;

        // Iterate over the from/to period range, inclusive of from and to.
        for (uint256 depositPeriod = params.fromDepositPeriod; depositPeriod <= params.toDepositPeriod; ++depositPeriod)
        {
            uint256 sharesAtPeriod = vault.sharesAtPeriod(params.owner, depositPeriod);

            uint256 amountAtPeriod = params.amountType == AmountType.Shares
                ? sharesAtPeriod
                : vault.convertToAssetsForDepositPeriod(sharesAtPeriod, depositPeriod, params.redeemPeriod);

            // If there is an Amount, store the value.
            if (amountAtPeriod > 0) {
                cacheDepositPeriods[arrayIndex] = depositPeriod;

                // check if we will go "over" the Amount To Find.
                if (amountFound + amountAtPeriod > params.amountToFind) {
                    uint256 amountToInclude = params.amountToFind - amountFound; // we only need the amount that brings us to amountToFind

                    // only include equivalent amount of shares for the amountToInclude assets
                    cacheSharesAtPeriods[arrayIndex] = params.amountType == AmountType.Shares
                        ? amountToInclude
                        : vault.convertToAssetsForDepositPeriod(amountToInclude, depositPeriod, params.redeemPeriod);

                    // optimization succeeded - return here to be explicit we exit the function at this point
                    return _trimToSize(arrayIndex, cacheDepositPeriods, cacheSharesAtPeriods);
                } else {
                    cacheSharesAtPeriods[arrayIndex] = sharesAtPeriod;
                }

                amountFound += amountAtPeriod;
                arrayIndex++;
            }
        }

        if (amountFound < params.amountToFind) {
            revert RedeemOptimizer__OptimizerFailed(amountFound, params.amountToFind);
        }

        return _trimToSize(arrayIndex, cacheDepositPeriods, cacheSharesAtPeriods);
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
        private
        pure
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
