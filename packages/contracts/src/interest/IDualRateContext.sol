// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ICalcInterestMetadata } from "@credbull/interest/ICalcInterestMetadata.sol";

/**
 * @title IDualRateContext
 * @dev Extension of the ICalcInterestMetadata to provide two interest rates:
 * 1. A rate that applies when the holder holds the asset for the full period (full rate).
 * 2. A reduced rate that applies when the holder does not meet the full period (reduced rate).
 */
interface IDualRateContext is ICalcInterestMetadata {
    /**
     * @notice Returns the interest rate when the holder holds for the full period.
     * @return fullRateInPercentage The full interest rate expressed as a percentage.
     */
    function fullRate() external view returns (uint256 fullRateInPercentage);

    /**
     * @notice Returns the reduced interest rate when the holder does not hold for the full period.
     * @return reducedRateInPercentage The reduced interest rate expressed as a percentage.
     */
    function reducedRate() external view returns (uint256 reducedRateInPercentage);

    /**
     * @notice Returns the number of periods required to qualify for the full interest rate.
     * @return numPeriods The number of periods required to earn the full interest rate.
     */
    function periodsForFullRate() external view returns (uint256 numPeriods);
}
