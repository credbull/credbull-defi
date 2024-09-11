// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title Interest Interface
 * @dev calculate interest e.g. SimpleInterest
 */
interface IInterest {
  /**
   * @notice Calculates the simple interest based on the principal and elapsed time periods.
   * @param principal The initial principal amount.
   * @param numTimePeriodsElapsed The number of time periods for which interest is calculated.
   * @return interest The calculated interest amount.
   */
  function calcInterest(uint256 principal, uint256 numTimePeriodsElapsed) external view returns (uint256 interest);

  /**
   * @notice Internal function to calculate the interest with scaling applied using the interest rate percentage.
   * @dev - return value is scaled as Interest * SCALE.  For example: Interest=1.01 and Scale=100 returns 101
   * @param principal The initial principal amount.
   * @param numTimePeriodsElapsed The number of time periods for which interest is calculated.
   * @param interestRatePercentage The interest rate as a percentage.
   * @param frequency The frequency of interest application
   * @return interest The scaled interest amount.
   */
  function calcInterest(uint256 principal, uint256 numTimePeriodsElapsed, uint256 interestRatePercentage, uint256 frequency) external view returns (uint256 interest);
}
