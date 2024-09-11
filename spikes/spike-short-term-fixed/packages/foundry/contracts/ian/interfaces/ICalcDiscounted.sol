// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { ICalcInterestMetadata } from "./ICalcInterestMetadata.sol";

/**
 * @title IDiscountedPrincipal Interface
 * @dev This interface provides functions to calculate "Discounted" Principal over time.
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
interface ICalcDiscounted is ICalcInterestMetadata {
  /**
   * @notice Calculates the discounted principal after the elapsed time periods.
   * @param principal The initial principal amount.
   * @param numTimePeriodsElapsed The number of time periods for which the discount is calculated.
   * @return discounted The discounted principal amount.
   */
  function calcDiscounted(uint256 principal, uint256 numTimePeriodsElapsed) external view returns (uint256 discounted);

  function calcDiscounted(
    uint256 principal,
    uint256 numTimePeriodsElapsed,
    uint256 interestRatePercentage,
    uint256 frequency
  ) external view returns (uint256 discounted);

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


  function calcPrincipalFromDiscounted(
    uint256 discounted,
    uint256 numTimePeriodsElapsed,
    uint256 interestRatePercentage,
    uint256 frequency
  ) external view returns (uint256 principal);

}
