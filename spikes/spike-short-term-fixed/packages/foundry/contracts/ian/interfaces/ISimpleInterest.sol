// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title Simple Interest Interface
 * @dev This interface provides functions to calculate interest and principal amounts over time.
 *
 * @notice The `calcPrincipalFromDiscounted` and `calcDiscounted` functions are designed to be mathematical inverses of each other.
 * This means that applying `calcPrincipalFromDiscounted` to the output of `calcDiscounted` will return the original principal amount.
 *
 * For example:
 * ```
 * uint256 originalPrincipal = 1000;
 * uint256 discountedValue = calcDiscounted(originalPrincipal);
 * uint256 recoveredPrincipal = calcPrincipalFromDiscounted(discountedValue);
 * assert(recoveredPrincipal == originalPrincipal);
 * ```
 *
 * This property ensures that no information is lost when discounting and then recovering the principal,
 * making the system consistent and predictable.
 */
interface ISimpleInterest {
  /**
   * @notice Calculates the simple interest based on the principal and elapsed time periods.
   * @param principal The initial principal amount.
   * @param numTimePeriodsElapsed The number of time periods for which interest is calculated.
   * @return interest The calculated interest amount.
   */
  function calcInterest(uint256 principal, uint256 numTimePeriodsElapsed) external view returns (uint256 interest);

  /**
   * @notice Calculates the discounted principal by subtracting the accrued interest.
   * @param principal The initial principal amount.
   * @param numTimePeriodsElapsed The number of time periods for which interest is calculated.
   * @return discounted The discounted principal amount.
   */
  function calcDiscounted(uint256 principal, uint256 numTimePeriodsElapsed) external view returns (uint256 discounted);

  /**
   * @notice Recovers the original principal from a discounted value by adding back the interest.
   * @param discounted The discounted principal amount.
   * @param numTimePeriodsElapsed The number of time periods for which interest was calculated.
   * @return principal The recovered original principal amount.
   */
  function calcPrincipalFromDiscounted(
    uint256 discounted,
    uint256 numTimePeriodsElapsed
  ) external view returns (uint256 principal);

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
}
