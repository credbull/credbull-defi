// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ICalcInterestMetadata } from "@credbull/interest/ICalcInterestMetadata.sol";

/**
 * @title IDualRateContext
 * @dev Context for yield calculations with full and reduced rates, expressed in percentage terms and scaled.
 * For example, at scale 1e3, 5% is represented as 5000.
 */
interface IDualRateContext is ICalcInterestMetadata {
    /// @notice Returns the full interest rate, scaled.
    function fullRateScaled() external view returns (uint256 fullRateInPercentageScaled);

    /// @notice Returns the reduced interest rate, scaled.
    function reducedRateScaled() external view returns (uint256 reducedRateInPercentageScaled);

    /// @notice Returns the number of periods required to earn the full rate.
    function numPeriodsForFullRate() external view returns (uint256 numPeriods);
}
