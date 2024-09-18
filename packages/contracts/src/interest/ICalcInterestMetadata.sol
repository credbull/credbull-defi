// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @dev Metadata required for Interest calculations
 */
interface ICalcInterestMetadata {
    /**
     * @notice Returns the frequency of interest application (number of periods in a year).
     * @return frequency The frequency value.
     */
    function frequency() external view returns (uint256 frequency);

    /**
     * @notice Returns the annual interest rate as a percentage * scale
     * @return rateInPercentageScaled The interest rate as a percentage * SCALE (e.g. "15_000" for 15% * scale[1e3])
     */
    function rateScaled() external view returns (uint256 rateInPercentageScaled);

    /**
     * @notice Returns the scale factor for internal calculations (e.g., 1e18 for 18 decimals).
     * @return scale The scale factor.
     */
    function scale() external view returns (uint256 scale);
}
