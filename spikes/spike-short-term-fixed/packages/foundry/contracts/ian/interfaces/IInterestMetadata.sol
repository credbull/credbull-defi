// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { IInterest } from "@credbull-spike/contracts/ian/interfaces/IInterest.sol";

/**
 * @dev extension to the Interest Interface to add metadata
 */
interface IInterestMetadata is IInterest {

  /**
   * @notice Returns the frequency of interest application (number of periods in a year).
   * @return frequency The frequency value.
   */
  function getFrequency() external view returns (uint256 frequency);

  /**
   * @notice Returns the annual interest rate as a percentage.
   * @return interestRateInPercentage The interest rate as a percentage.
   */
  function getInterestInPercentage() external view returns (uint256 interestRateInPercentage);

  /**
   * @notice Returns the scale factor for internal calculations (e.g., 10^18 for 18 decimals).
   * @return scale The scale factor.
   */
  function getScale() external view returns (uint256 scale);
}
