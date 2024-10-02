// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ICalcInterestMetadata } from "@credbull/yield/ICalcInterestMetadata.sol";

/**
 * @title Our dual rate context, with the 'full' rate and 1 reduced rate.
 * @author credbull
 * @dev Context for yield calculations with full and reduced rates, expressed in percentage terms and scaled.
 *  For example, at scale 1e3, 5% is represented as 5000. The 'full' rate values are encapsulated by the
 *  [ICalcInterestMetadata].
 */
interface IDualRateContext is ICalcInterestMetadata {
    /// @notice Returns the number of periods required to earn the full rate.
    function numPeriodsForFullRate() external view returns (uint256 numPeriods);

    /// @notice Returns the reduced interest rate, scaled.
    function reducedRateScaled() external view returns (uint256 reducedRateInPercentageScaled);
}
