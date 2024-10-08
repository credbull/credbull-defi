// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IMultiTokenVault } from "@credbull/token/ERC1155/IMultiTokenVault.sol";
import { IRedeemOptimizer } from "@credbull/token/ERC1155/IRedeemOptimizer.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title The redemption optimizer utilising a combined FIFO/LIFO strategy.
 * @notice Optimizes the redemption of shares using a FIFO strategy with a LIFO component.
 * @dev The strategy is applied FIFO first and, if needed, LIFO. FIFO selects mature deposits to redeem to maximise
 *  the value returned while minimising deposits redeemed. If more value is required, then LIFO selects the most recent
 *  first deposits, to make up the value and reduce the loss of invested time in the older deposits.
 */
contract RedeemOptimizerFIFOLIFO is IRedeemOptimizer {
    using Math for uint256;

    error RedeemOptimizer__InvalidDepositPeriodRange(uint256 fromPeriod, uint256 toPeriod);
    error RedeemOptimizer__FutureToDepositPeriod(uint256 toPeriod, uint256 currentPeriod);
    error RedeemOptimizer__OptimizerFailed(uint256 amountFound, uint256 amountToFind);

    OptimizerBasis public immutable DEFAULT_BASIS;
    uint256 public immutable START_DEPOSIT_PERIOD;
    uint256 public immutable TENOR;

    uint256 private _startDepositPeriod;

    // NOTE (JL,2024-10-08): Instead of Tenor, could pass in the `IYieldStrategy` to do calculations?
    constructor(OptimizerBasis defaultBasis, uint256 startDepositPeriod, uint256 tenor) {
        DEFAULT_BASIS = defaultBasis;
        START_DEPOSIT_PERIOD = startDepositPeriod;
        TENOR = tenor;

        _startDepositPeriod = START_DEPOSIT_PERIOD;
    }

    /// @inheritdoc IRedeemOptimizer
    function optimize(IMultiTokenVault vault, address owner, uint256 shares, uint256 assets, uint256 redeemPeriod)
        public
        override
        returns (uint256[] memory depositPeriods_, uint256[] memory sharesAtPeriods_)
    {
        return OptimizerBasis.AssetsWithReturns == DEFAULT_BASIS
            ? optimizeWithdrawAssets(vault, owner, assets, redeemPeriod)
            : optimizeRedeemShares(vault, owner, shares, redeemPeriod);
    }

    /// @inheritdoc IRedeemOptimizer
    function optimizeRedeemShares(IMultiTokenVault vault, address owner, uint256 shares, uint256 redeemPeriod)
        public
        override
        returns (uint256[] memory depositPeriods_, uint256[] memory sharesAtPeriods_)
    {
        return _findAmount(
            vault,
            OptimizerParams({
                owner: owner,
                amountToFind: shares,
                fromDepositPeriod: _earliestPeriodWithDeposit(vault),
                toDepositPeriod: vault.currentPeriodsElapsed(),
                redeemPeriod: redeemPeriod,
                optimizerBasis: OptimizerBasis.Shares
            })
        );
    }

    /// @inheritdoc IRedeemOptimizer
    /// @dev - assets include deposit (principal) and any returns up to the redeem period
    function optimizeWithdrawAssets(IMultiTokenVault vault, address owner, uint256 assets, uint256 redeemPeriod)
        public
        override
        returns (uint256[] memory depositPeriods, uint256[] memory sharesAtPeriods)
    {
        return _findAmount(
            vault,
            OptimizerParams({
                owner: owner,
                amountToFind: assets,
                fromDepositPeriod: _earliestPeriodWithDeposit(vault),
                toDepositPeriod: vault.currentPeriodsElapsed(),
                redeemPeriod: redeemPeriod,
                optimizerBasis: OptimizerBasis.AssetsWithReturns
            })
        );
    }

    /// @dev Queries the `vault` to find the earliest Deposit Period at which there are deposits. Sets this value as
    /// `_startDepositPeriod`, the starting point for the optimizer and returns the same value.
    /// @return _startDepositPeriod The earliest Deposit Period at which there are deposits.
    function _earliestPeriodWithDeposit(IMultiTokenVault vault) internal returns (uint256) {
        for (uint256 period = _startDepositPeriod; period <= vault.currentPeriodsElapsed(); ++period) {
            if (vault.exists(period)) {
                _startDepositPeriod = period;
                break;
            }
        }
        return _startDepositPeriod;
    }

    /// @dev Calculates the effective Period Span between a From and a To date.
    // TODO (JL,2024-10-08): Could we expose this on the IYieldStrategy? As effective span is a yield concept.
    function _inclusivePeriodSpan(OptimizerParams memory optimizerParams) internal pure returns (uint256) {
        return (optimizerParams.toDepositPeriod - optimizerParams.fromDepositPeriod) + 1;
    }

    /// @dev Calculates the latest Deposit Period that can be mature. Only invoke from a context where it is known that
    ///  the period span is greater than the tenor. So, the subtraction is safe.
    function _lastMatureDepositPeriod(OptimizerParams memory optimizerParams) internal view returns (uint256) {
        return (optimizerParams.toDepositPeriod - TENOR) + 1;
    }

    /// @dev Calculates the first Deposit Period that cannot be mature.
    function _firstImmatureDepositPeriod(OptimizerParams memory optimizerParams) internal view returns (uint256) {
        if (_inclusivePeriodSpan(optimizerParams) >= TENOR) {
            return _lastMatureDepositPeriod(optimizerParams) + 1;
        } else {
            return optimizerParams.fromDepositPeriod;
        }
    }

    function _findAmount(IMultiTokenVault vault, OptimizerParams memory optimizerParams)
        internal
        view
        returns (uint256[] memory depositPeriods, uint256[] memory sharesAtPeriods)
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
        IterationData memory i = IterationData({
            vault: vault,
            optimizerParams: optimizerParams,
            arrayIndex: 0,
            depositPeriod: 0,
            amountFound: 0,
            depositPeriods: new uint256[](_inclusivePeriodSpan(optimizerParams)),
            sharesAtPeriods: new uint256[](_inclusivePeriodSpan(optimizerParams)),
            isDone: false
        });

        // If there are mature deposits.
        if (_inclusivePeriodSpan(optimizerParams) >= TENOR) {
            // Iterate over the from -> last mature period range, inclusive of both.
            uint256 lastMatureDepositPeriod = _lastMatureDepositPeriod(optimizerParams);
            for (
                uint256 depositPeriod = optimizerParams.fromDepositPeriod;
                depositPeriod <= lastMatureDepositPeriod && !i.isDone;
                ++depositPeriod
            ) {
                i.depositPeriod = depositPeriod;
                i = _iteration(i);
            }
        }

        // If the Amount Found is not satisfied, search for value in the immature deposits.
        if (i.amountFound < optimizerParams.amountToFind && !i.isDone) {
            // Search in the range of the first immature deposit period -> to period.
            return _findMostRecentFirst(_firstImmatureDepositPeriod(optimizerParams), i);
        }

        return _trimToSize(i.arrayIndex, i.depositPeriods, i.sharesAtPeriods);
    }

    /**
     * @dev Reverse iterates from the `to` period to the `firstImmaturePeriod` finding the most recent deposits that
     *  can be added to the redeem amount. This gives the older, not yet mature deposits more time to mature.
     *
     * @param firstImmaturePeriod The initial period in the redeem range that cannot be a mature deposit.
     * @param i The [IterationData] that encapsulates the processing to this point.
     * @return depositPeriods The result array of Deposit Periods to harvest.
     * @return sharesAtPeriods The result array of Share Amounts At Periods to harvest.
     */
    function _findMostRecentFirst(uint256 firstImmaturePeriod, IterationData memory i)
        internal
        view
        returns (uint256[] memory depositPeriods, uint256[] memory sharesAtPeriods)
    {
        // Reverse iterate over the to -> first non-mature period range, inclusive of both.
        for (
            uint256 depositPeriod = i.optimizerParams.toDepositPeriod;
            depositPeriod >= firstImmaturePeriod && !i.isDone;
            --depositPeriod
        ) {
            i.depositPeriod = depositPeriod;
            i = _iteration(i);
            if (depositPeriod == 0) break; // Prevent underflow by exiting loop before final decrement.
        }

        if (i.amountFound < i.optimizerParams.amountToFind) {
            revert RedeemOptimizer__OptimizerFailed(i.amountFound, i.optimizerParams.amountToFind);
        }

        return _trimToSize(i.arrayIndex, i.depositPeriods, i.sharesAtPeriods);
    }

    /// @notice A struct to capture all the data that is iterated over. A means to reduce Stack Depth.
    struct IterationData {
        /// @dev The [IMultiTokenVault] we are querying against.
        IMultiTokenVault vault;
        /// @dev The [OptimizerParams] governing how we optimise for the redemption/withdrawal.
        OptimizerParams optimizerParams;
        /// @dev The current index of results written to the result array pair.
        uint256 arrayIndex;
        /// @dev The current Deposit Period which we are processing for.
        uint256 depositPeriod;
        /// @dev The sum of amounts found so far.
        uint256 amountFound;
        /// @dev The Deposit Period result array.
        uint256[] depositPeriods;
        /// @dev The Share Amounts At Period result array.
        uint256[] sharesAtPeriods;
        bool isDone;
    }

    /**
     * @dev Encapsulates the processing of an iteration of one of the Period Ranges.
     *
     * @param i The [IterationData] capturing the current state of the processing.
     * @return _updated The updated [IterationData].
     */
    function _iteration(IterationData memory i) internal view returns (IterationData memory _updated) {
        uint256 sharesAtPeriod = i.vault.sharesAtPeriod(i.optimizerParams.owner, i.depositPeriod);
        uint256 amountAtPeriod = i.optimizerParams.optimizerBasis == OptimizerBasis.Shares
            ? sharesAtPeriod
            : i.vault.convertToAssetsForDepositPeriod(sharesAtPeriod, i.depositPeriod, i.optimizerParams.redeemPeriod);

        // If there is an Amount, store the value.
        if (amountAtPeriod > 0) {
            i.depositPeriods[i.arrayIndex] = i.depositPeriod;

            // check if we will go "over" the Amount To Find.
            if (i.amountFound + amountAtPeriod > i.optimizerParams.amountToFind) {
                // we only need the amount that brings us to amountToFind
                uint256 amountToInclude = i.optimizerParams.amountToFind - i.amountFound;

                // in the assets case, the amounts include principal AND returns.  we want the shares on deposit,
                // which is the principal only.
                // use this ratio: partialShares / totalShares = partialAssets / totalAssets
                //                 partialShares = (partialAssets * totalShares) / totalAssets
                uint256 sharesToInclude = sharesAtPeriod.mulDiv(amountToInclude, amountAtPeriod);

                // only include equivalent amount of shares for the amountToInclude assets
                i.sharesAtPeriods[i.arrayIndex] =
                    i.optimizerParams.optimizerBasis == OptimizerBasis.Shares ? amountToInclude : sharesToInclude;

                i.amountFound += amountToInclude;
                i.isDone = true;
            } else {
                i.sharesAtPeriods[i.arrayIndex] = sharesAtPeriod;
                i.amountFound += amountAtPeriod;
            }
            i.arrayIndex++;

            if (i.amountFound == i.optimizerParams.amountToFind && !i.isDone) {
                i.isDone = true;
            }
        }
        return i;
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
