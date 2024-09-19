// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ICalcInterestMetadata
 * @dev Interface for providing metadata required for interest calculations.
 */
interface ICalcInterestMetadata {
    /// @notice Returns the frequency of interest application.
    function frequency() external view returns (uint256 frequency);

    /// @notice Returns the scaled annual interest rate as a percentage.
    function rateScaled() external view returns (uint256 rateInPercentageScaled);

    /// @notice Returns the scale factor used in calculations.
    function scale() external view returns (uint256 scale);
}
