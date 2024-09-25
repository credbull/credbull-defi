// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ICalcInterestMetadata } from "@credbull/interest/ICalcInterestMetadata.sol";

/**
 * @title IDynamicDualRateContext
 * @dev Context for yield calculations with a singluar full rate and variable reduced rates, expressed in percentage
 *  terms and scaled. The variable reduced rate apply from a specified period.
 */
interface IDynamicDualRateContext is ICalcInterestMetadata {
    /// @notice Returns the full interest rate, scaled.
    function fullRateScaled() external view returns (uint256 fullRateInPercentageScaled);

    /// @notice Returns the number of periods required to earn the full rate.
    function numPeriodsForFullRate() external view returns (uint256 numPeriods);

    /// @notice Returns the effective Reduced Rates for the `fromPeriod` to `toPeriod` Period Range.
    function reducedRatesFor(uint256 fromPeriod, uint256 toPeriod)
        external
        view
        returns (uint256[][] memory reducedRateScaled);
}
