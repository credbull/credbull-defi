// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @dev extension to the Interest Interface to add metadata
 */
interface ICalcInterestMetadata {
    /**
     * @notice Returns the frequency of interest application (number of periods in a year).
     * @return frequency The frequency value.
     */
    function frequency() external view returns (uint256 frequency);

    /**
     * @notice Returns the annual interest rate as a percentage.
     * @return interestRateInPercentage The interest rate as a percentage.
     */
    function interestRate() external view returns (uint256 interestRateInPercentage);

    /**
     * @notice Returns the scale factor for internal calculations (e.g., 10^18 for 18 decimals).
     * @return scale The scale factor.
     */
    function scale() external view returns (uint256 scale);
}
