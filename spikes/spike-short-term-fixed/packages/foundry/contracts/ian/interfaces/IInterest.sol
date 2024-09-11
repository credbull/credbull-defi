// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title Interest Interface
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
interface IInterest {
  /**
   * @notice Calculates the simple interest based on the principal and elapsed time periods.
   * @param principal The initial principal amount.
   * @param numTimePeriodsElapsed The number of time periods for which interest is calculated.
   * @return interest The calculated interest amount.
   */
  function calcInterest(uint256 principal, uint256 numTimePeriodsElapsed) external view returns (uint256 interest);

  /**
   * @notice Calculates the discounted principal after the elapsed time periods.
   * @param principal The initial principal amount.
   * @param numTimePeriodsElapsed The number of time periods for which the discount is calculated.
   * @return discounted The discounted principal amount.
   */
  function calcDiscounted(uint256 principal, uint256 numTimePeriodsElapsed) external view returns (uint256 discounted);

  /**
   * @notice Calculates the price for a given number of periods elapsed.
   * Price represents the accrued interest over time for a Principal of 1.
   * @dev - return value is scaled as Price * SCALE.  For example: Price=1.01 and Scale=100 returns 101
   * @param numTimePeriodsElapsed The number of time periods that have elapsed.
   * @return priceScaled The price scaled by the internal scale factor.
   */
  function calcPriceWithScale(uint256 numTimePeriodsElapsed) external view returns (uint256 priceScaled);

  /**
   * @notice Recovers the original principal from a discounted value after the elapsed time periods.
   * @param discounted The discounted principal amount.
   * @param numTimePeriodsElapsed The number of time periods for which the discount was calculated.
   * @return principal The recovered original principal amount.
   */
  function calcPrincipalFromDiscounted(
    uint256 discounted,
    uint256 numTimePeriodsElapsed
  ) external view returns (uint256 principal);

}
