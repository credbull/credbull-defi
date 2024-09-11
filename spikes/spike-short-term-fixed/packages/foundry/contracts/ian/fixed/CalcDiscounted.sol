// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { ICalcDiscounted } from "@credbull-spike/contracts/ian/interfaces/ICalcDiscounted.sol";
import { CalcSimpleInterest } from "@credbull-spike/contracts/ian/fixed/CalcSimpleInterest.sol";

/**
 * @title CalcDiscounted
 * @dev This library implements the calculation of discounted principal, and recovery of the original principal using the Price mechanism.
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
 */
library CalcDiscounted {
  using Math for uint256;

  /**
   * @notice Calculates the price for a given number of periods elapsed.
   * Price represents the accrued interest over time for a Principal of 1.
   * @dev - return value is scaled as Price * SCALE.  For example: Price=1.01 and Scale=100 returns 101
   * @param numTimePeriodsElapsed The number of time periods that have elapsed.
   * @return priceScaled The price scaled by the internal scale factor.
   */
  function calcPriceWithScale(
    uint256 numTimePeriodsElapsed,
    uint256 interestRatePercentage,
    uint256 frequency
  ) public view returns (uint256 priceScaled) {
    uint256 parScaled = CalcSimpleInterest._scale(1);

    uint256 interestScaled = CalcSimpleInterest._calcInterestWithScale(parScaled, numTimePeriodsElapsed, interestRatePercentage, frequency);

    uint256 _priceScaled = CalcSimpleInterest._scale(parScaled) + interestScaled;

    return _priceScaled;
  }

  /**
   * @notice Calculates the discounted principal by dividing the principal by the price.
   * @param principal The initial principal amount.
   * @param numTimePeriodsElapsed The number of time periods for which interest is calculated.
   * @return discounted The discounted principal amount.
   */
  function calcDiscounted(
    uint256 principal,
    uint256 numTimePeriodsElapsed,
    uint256 interestRatePercentage,
    uint256 frequency
  ) public view returns (uint256 discounted) {
    uint256 scale = CalcSimpleInterest.getScale();

    uint256 priceScaled = calcPriceWithScale(numTimePeriodsElapsed, interestRatePercentage, frequency);

    uint256 discountedScaled = CalcSimpleInterest._scale(principal).mulDiv(scale * scale, priceScaled, Math.Rounding.Floor); // Discounted = Principal / Price

    return CalcSimpleInterest._unscale(discountedScaled);
  }

  /**
   * @notice Recovers the original principal from a discounted value by multiplying it with the price.
   * @param discounted The discounted principal amount.
   * @param numTimePeriodsElapsed The number of time periods for which interest was calculated.
   * @return principal The recovered original principal amount.
   */
  function calcPrincipalFromDiscounted(
    uint256 discounted,
    uint256 numTimePeriodsElapsed,
    uint256 interestRatePercentage,
    uint256 frequency
  ) public view returns (uint256 principal) {
    uint256 scale = CalcSimpleInterest.getScale();

    uint256 priceScaled = calcPriceWithScale(numTimePeriodsElapsed, interestRatePercentage, frequency);

    uint256 principalScaled = CalcSimpleInterest._scale(discounted).mulDiv(priceScaled, scale * scale, Math.Rounding.Floor); // Principal = Discounted * Price

    return CalcSimpleInterest._unscale(principalScaled);
  }

}