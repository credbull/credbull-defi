// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ICalcInterestMetadata } from "@credbull/yield/ICalcInterestMetadata.sol";

/**
 * @title A triple rate context, with the 'full' rate and 2 reduced rates that apply temporally across 2 tenor periods.
 * @dev Context for yield calculations with a rate and dual reduced rates, applicable across Tenor Periods. All rate
 *  are expressed in percentage terms and scaled using [scale()]. The 'full' rate values are encapsulated by the
 *  [ICalcInterestMetadata].
 */
interface ITripleRateContext is ICalcInterestMetadata {
    /// @notice Returns the number of periods required to earn the full rate.
    function numPeriodsForFullRate() external view returns (uint256 numPeriods);

    /**
     * @notice Returns a tuple of the current Tenor Period and its associated Reduced Rate.
     *
     * @return currentTenorPeriod The current Tenor Period.
     * @return reducedRateInPercentageScaled The associated Reduced Rate.
     */
    function currentTenorPeriodAndRate()
        external
        view
        returns (uint256 currentTenorPeriod, uint256 reducedRateInPercentageScaled);

    /**
     * @notice Returns a tuple of the previous Tenor Period and its associated Reduced Rate.
     *
     * @return previousTenorPeriod The previous Tenor Period.
     * @return reducedRateInPercentageScaled The associated Reduced Rate.
     */
    function previousTenorPeriodAndRate()
        external
        view
        returns (uint256 previousTenorPeriod, uint256 reducedRateInPercentageScaled);
}
