// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { ICalcDiscounted } from "@credbull-spike/contracts/ian/interfaces/ICalcDiscounted.sol";
import { CalcSimpleInterest } from "@credbull-spike/contracts/ian/fixed/CalcSimpleInterest.sol";

/**
 * @title CalcDiscounted
 * @dev This contract implements the calculation of discounted principal, and recovery of the original principal using the Price mechanism.
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
contract CalcDiscounted is ICalcDiscounted, CalcSimpleInterest {
  using Math for uint256;

  uint256 public constant PAR = 1;

  /**
   * @notice Constructor to initialize the SimpleInterest contract with interest rate, frequency, and scaling parameters.
   * @param interestRatePercentage The annual interest rate as a percentage.
   * @param frequency The number of interest periods in a year.
   * @param decimals The number of decimals for scaling calculations.
   */
  constructor(
    uint256 interestRatePercentage,
    uint256 frequency,
    uint256 decimals
  )
    CalcSimpleInterest(
      CalcInterestParams({ interestRatePercentage: interestRatePercentage, frequency: frequency, decimals: decimals })
    )
  { }

  /**
   * @notice Calculates the price for a given number of periods elapsed.
   * Price represents the accrued interest over time for a Principal of 1.
   * @dev - return value is scaled as Price * SCALE.  For example: Price=1.01 and Scale=100 returns 101
   * @param numTimePeriodsElapsed The number of time periods that have elapsed.
   * @return priceScaled The price scaled by the internal scale factor.
   */
  function calcPriceWithScale(uint256 numTimePeriodsElapsed) public view virtual returns (uint256 priceScaled) {
    uint256 interestScaled = _calcInterestWithScale(PAR, numTimePeriodsElapsed, INTEREST_RATE, FREQUENCY);

    uint256 _priceScaled = _scale(PAR) + interestScaled;

    return _priceScaled;
  }

  /**
   * @notice Calculates the discounted principal by dividing the principal by the price.
   * @param principal The initial principal amount.
   * @param numTimePeriodsElapsed The number of time periods for which interest is calculated.
   * @return discounted The discounted principal amount.
   */
  function calcDiscounted(uint256 principal, uint256 numTimePeriodsElapsed) public view returns (uint256 discounted) {
    if (principal < SCALE) {
      revert PrincipalLessThanScale(principal, SCALE);
    }
    uint256 priceScaled = calcPriceWithScale(numTimePeriodsElapsed);

    uint256 discountedScaled = _scale(principal).mulDiv(SCALE, priceScaled, ROUNDING); // Discounted = Principal / Price

    return _unscale(discountedScaled);
  }

  /**
   * @notice Recovers the original principal from a discounted value by multiplying it with the price.
   * @param discounted The discounted principal amount.
   * @param numTimePeriodsElapsed The number of time periods for which interest was calculated.
   * @return principal The recovered original principal amount.
   */
  function calcPrincipalFromDiscounted(
    uint256 discounted,
    uint256 numTimePeriodsElapsed
  ) public view virtual returns (uint256 principal) {
    uint256 priceScaled = calcPriceWithScale(numTimePeriodsElapsed);

    uint256 principalScaled = _scale(discounted).mulDiv(priceScaled, SCALE, ROUNDING); // Principal = Discounted * Price

    return _unscale(principalScaled);
  }
}
