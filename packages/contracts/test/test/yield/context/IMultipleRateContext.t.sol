// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ICalcInterestMetadata } from "@credbull/yield/ICalcInterestMetadata.sol";

/**
 * @title Our multiple rate context, with the 'full' rate and many reduced rates that apply temporally.
 * @author credbull
 * @dev Context for yield calculations with a rate and many reduced rates, applicable per period. All rate values
 *  are expressed in percentage terms and scaled using [scale()]. The 'full' rate values are encapsulated by the
 *  [ICalcInterestMetadata].
 */
interface IMultipleRateContext is ICalcInterestMetadata {
    /**
     * @notice Reverts when the `from` and `to` periods do not represent a valid period range.
     * @param from the start/earlier period
     * @param to the end/later period.
     */
    error IMultipleRateContext_InvalidPeriodRange(uint256 from, uint256 to);

    /// @notice Returns the number of periods required to earn the full rate.
    function numPeriodsForFullRate() external view returns (uint256 numPeriods);

    /**
     * @notice Returns the effective Reduced Rates for the `fromPeriod` to `toPeriod` Period Range.
     * @dev The result includes the Reduced Rate effective before the `fromPeriod`.
     *  Reverts with [IMultipleRateContext_InvalidPeriodRange] when `fromPeriod` and `toPeriod` form an invalid
     * Period Range.
     *
     * @param fromPeriod The start period, inclusive, of the Period Range.
     * @param toPeriod The end period, inclusive, of the Period Range.
     * @return reducedRatesScaled The array or tuples of Period to applicable Reduced Rate Scaled.
     */
    function reducedRatesFor(uint256 fromPeriod, uint256 toPeriod)
        external
        view
        returns (uint256[][] memory reducedRatesScaled);
}
