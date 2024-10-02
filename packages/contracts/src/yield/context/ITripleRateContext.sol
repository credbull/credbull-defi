// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ICalcInterestMetadata } from "@credbull/yield/ICalcInterestMetadata.sol";

/**
 * @title A triple rate context, with the 'full' interest rate and 2 reduced interest rates that apply temporally
 *  across 2 tenor periods.
 * @dev Context for yield calculations with an interest rate and dual reduced interest rates, applicable across Tenor
 *  Periods. All rate are expressed in percentage terms and scaled using [scale()]. The 'full' rate values are
 *  encapsulated by the [ICalcInterestMetadata].
 */
interface ITripleRateContext is ICalcInterestMetadata {
    /// @notice Associates an Interest Rate with the Period from which it applies.
    struct PeriodRate {
        /// @dev The Interest Rate in percentage terms and scaled.
        uint256 interestRate;
        /// @dev The Period from which the associated rate applies.
        uint256 effectiveFromPeriod;
    }

    /// @notice Returns the number of periods required to earn the full rate.
    function numPeriodsForFullRate() external view returns (uint256 numPeriods);

    /**
     * @notice Returns the [PeriodRate] of the current (at invocation) Reduced Interest Rate and its
     *  associated Period.
     *
     * @return currentPeriodRate_ The current [PeriodRate].
     */
    function currentPeriodRate() external view returns (PeriodRate memory currentPeriodRate_);

    /**
     * @notice Returns the [PeriodRate] of the previous Reduced Interest Rate and its associated Period.
     * @dev When the current [PeriodRate] is set, its existing value becomes the previous [PeriodRate].
     *
     * @return previousPeriodRate_ The previous [PeriodRate].
     */
    function previousPeriodRate() external view returns (PeriodRate memory previousPeriodRate_);
}
