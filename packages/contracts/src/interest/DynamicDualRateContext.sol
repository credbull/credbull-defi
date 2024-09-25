// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { EnumerableMap } from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

import { CalcInterestMetadata } from "@credbull/interest/CalcInterestMetadata.sol";
import { IDynamicDualRateContext } from "@credbull/interest/IDynamicDualRateContext.sol";

/**
 * @title A dual rate context (full & reduced) where the Reduced Rates are configurable and many.
 * @author credbull
 * @notice A reference implementation of [IDynamicDualRateContext].
 */
contract DynamicDualRateContext is CalcInterestMetadata, IDynamicDualRateContext {
    using EnumerableMap for EnumerableMap.UintToUintMap;
    using Math for uint256;

    error DynamicDualRateContext_InvalidPeriodRange(uint256 from, uint256 to);
    error DynamicDualRateContext_InvalidReducedRatePeriod(uint256 from);

    event DynamicDualRateContext_ReducedRateAdded(uint256 period, uint256 rateScaled, uint256 scale);
    event DynamicDualRateContext_ReducedRateRemoved(uint256 period, uint256 rateScaled, uint256 scale);

    uint256 public immutable DEFAULT_REDUCED_RATE;
    uint256 public immutable TENOR;

    /**
     * @notice A map of Period to the Reduced Rate effective from that period onwards.
     * @dev Only 1 Reduced Rate per Period is supported, thus a map.
     */
    EnumerableMap.UintToUintMap internal reducedRatesMap;

    constructor(
        uint256 fullRateInPercentageScaled_,
        uint256 reducedRateInPercentageScaled_,
        uint256 frequency_,
        uint256 tenor_,
        uint256 decimals
    ) CalcInterestMetadata(fullRateInPercentageScaled_, frequency_, decimals) {
        DEFAULT_REDUCED_RATE = reducedRateInPercentageScaled_;
        TENOR = tenor_;
    }

    function fullRateScaled() public view returns (uint256 fullRateInPercentageScaled_) {
        return RATE_PERCENT_SCALED;
    }

    function numPeriodsForFullRate() public view returns (uint256 numPeriods) {
        return TENOR;
    }

    /**
     * @notice Determines the set of Reduced Rates for the period span of `fromPeriod` to `toPeriod`.
     * @dev Encapsulates a somewhat complex (loop-heavy) algorithm for determining the set of Reduced Rates applicable
     *  over a period span.
     *
     * @param fromPeriod The [uint256] period from which to determine the effective Reduced Rates.
     * @param toPeriod The [uint256] period to which to determine the effective Reduced Rates. Must be after
     *  `fromPeriod`.
     * @return reducedRatesScaled An array of pairs of `period` to `reducedRateScaled` of the Reduced Rates.
     */
    function reducedRatesFor(uint256 fromPeriod, uint256 toPeriod)
        public
        view
        override
        returns (uint256[][] memory reducedRatesScaled)
    {
        if (toPeriod <= fromPeriod) {
            revert DynamicDualRateContext_InvalidPeriodRange(fromPeriod, toPeriod);
        }

        // If there are no custom Reduced Rates, use the default Reduced Rate.
        if (reducedRatesMap.length() == 0) {
            reducedRatesScaled = matrixOf(1, DEFAULT_REDUCED_RATE);
        } else {
            // Determine the set of Periods to Reduced Rates from the configuration.
            uint256[][] memory cache = new uint256[][](toPeriod - fromPeriod + 1);
            uint256 cacheIndex = 0;

            // If 'fromPeriod' has no custom Reduced Rate, then we decrement from then until we find one.
            if (!reducedRatesMap.contains(fromPeriod)) {
                // We iterate down to 1, decrementing i. No 0-day rate is allowed.
                for (uint256 i = fromPeriod - 1; i > 0; i--) {
                    (bool isFound, uint256 rate) = reducedRatesMap.tryGet(i);
                    if (isFound) {
                        cache[cacheIndex++] = tupleOf(i, rate);
                        break;
                    }
                }

                // If still none found, then the default rate applies.
                if (cacheIndex == 0) {
                    cache[cacheIndex++] = tupleOf(1, DEFAULT_REDUCED_RATE);
                }
            } else {
                // If 'fromPeriod_' has a custom Reduced Rate, then that is the one that applies.
                cache[cacheIndex++] = tupleOf(fromPeriod, reducedRatesMap.get(fromPeriod));
            }

            // Enumerate over the period between 'from' + 1 and 'to', to determine if there are any custom Reduced Rates
            for (uint256 i = fromPeriod + 1; i <= toPeriod; i++) {
                (bool isFound, uint256 rate) = reducedRatesMap.tryGet(i);
                if (isFound) {
                    cache[cacheIndex++] = tupleOf(i, rate);
                }
            }

            // Now trim the cached results
            uint256[][] memory trimmed = new uint256[][](cacheIndex);
            for (uint256 i = 0; i < cacheIndex; i++) {
                trimmed[i] = tupleOf(cache[i][0], cache[i][1]);
            }

            reducedRatesScaled = trimmed;
        }
    }

    /**
     * @notice Sets a Reduced Rate to be effective from the specified Period, replacing any existing rate.
     * @dev Emits [TestDynamicDualRateContext_ReducedRateRemoved] first, when an existing rate is present. Emits
     *  [TestDynamicDualRateContext_ReducedRateAdded] when a rate is set. Expected to be Access Controlled.
     *
     * @param fromPeriod_ The [uint256] period from which the custom Reduced Rate applies.
     * @param reducedRate_ The [uint256] scaled Reduced Rate.
     */
    function setReducedRate(uint256 fromPeriod_, uint256 reducedRate_) public {
        if (fromPeriod_ == 0) {
            revert DynamicDualRateContext_InvalidReducedRatePeriod(fromPeriod_);
        }

        (bool isPresent, uint256 toReplace) = reducedRatesMap.tryGet(fromPeriod_);
        reducedRatesMap.set(fromPeriod_, reducedRate_);

        if (isPresent) {
            emit DynamicDualRateContext_ReducedRateRemoved(fromPeriod_, toReplace, SCALE);
        }
        emit DynamicDualRateContext_ReducedRateAdded(fromPeriod_, reducedRate_, SCALE);
    }

    /**
     * @notice Removes any existing Reduced Rate associated with `fromPeriod_`.
     * @dev Emits [TestDynamicDualRateContext_ReducedRateRemoved] when a rate is removed.
     *  Expected to be Access Controlled.
     *
     * @param fromPeriod_ The [uint256] period from which to remove any associated Reduced Rate.
     * @return wasRemoved [true] if a rate was removed, [false] otherwise.
     */
    function removeReducedRate(uint256 fromPeriod_) public returns (bool wasRemoved) {
        if (fromPeriod_ == 0) {
            revert DynamicDualRateContext_InvalidReducedRatePeriod(fromPeriod_);
        }

        (bool isPresent, uint256 toRemove) = reducedRatesMap.tryGet(fromPeriod_);
        if (isPresent) {
            if (reducedRatesMap.remove(fromPeriod_)) {
                emit DynamicDualRateContext_ReducedRateRemoved(fromPeriod_, toRemove, SCALE);
                return true;
            }
        }
        return false;
    }

    function tupleOf(uint256 left, uint256 right) private pure returns (uint256[] memory tuple) {
        tuple = new uint256[](2);
        tuple[0] = left;
        tuple[1] = right;
    }

    function matrixOf(uint256 left, uint256 right) private pure returns (uint256[][] memory matrix) {
        matrix = new uint256[][](1);
        matrix[0] = tupleOf(left, right);
    }
}
