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
    /// @notice Associates an Interest Rate with the Tenor Period from which it applies.
    struct TenorPeriodRate {
        /// @dev The Interest Rate in percentage terms and scaled.
        uint256 interestRate;
        /// @dev The Tenor Period from which the associated rate applies.
        uint256 effectiveFromTenorPeriod;
    }

    /// @notice Returns the number of periods required to earn the full rate.
    function numPeriodsForFullRate() external view returns (uint256 numPeriods);

    /**
     * @notice Returns the [TenorPeriodRate] of the current Reduced Interest Rate and its associated Tenor Period.
     *
     * @return currentTenorPeriodRate_ The current [TenorPeriodRate].
     */
    function currentTenorPeriodRate() external view returns (TenorPeriodRate memory currentTenorPeriodRate_);

    /**
     * @notice Returns the [TenorPeriodRate] of the previous Reduced Interest Rate and its associated Tenor Period.
     *
     * @return previousTenorPeriodRate_ The previous [TenorPeriodRate].
     */
    function previousTenorPeriodRate() external view returns (TenorPeriodRate memory previousTenorPeriodRate_);
}
