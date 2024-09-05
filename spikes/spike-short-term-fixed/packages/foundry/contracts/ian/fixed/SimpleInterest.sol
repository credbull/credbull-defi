// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { ISimpleInterest } from "@credbull-spike/contracts/ian/interfaces/ISimpleInterest.sol";

/**
 * @title SimpleInterest
 * @dev This contract implements the calculation of simple interest, discounted principal, and recovery of the original principal.
 *
 * https://en.wikipedia.org/wiki/Interest
 *
 * Simple interest is calculated only on the principal amount, or on that portion of the principal amount that remains.
 * It excludes the effect of compounding. Simple interest can be applied over a time period other than a year, for example, every month.
 *
 * Simple interest is calculated according to the following formula: (IR * P * m) / f
 * - IR is the simple annual interest rate
 * - P is the Principal (aka initial amount)
 * - m is the number of time periods elapsed
 * - f is the frequency of applying interest (how many interest periods in a year)
 *
 *
 *  @notice The `calcPrincipalFromDiscounted` and `calcDiscounted` functions are designed to be mathematical inverses of each other.
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
 * @notice The `calcPrincipalFromDiscounted` and `calcDiscounted` functions are designed to be mathematical inverses of each other,
 * ensuring that the original principal can be recovered from the discounted value.
 */
contract SimpleInterest is ISimpleInterest {
  using Math for uint256;

  uint256 public immutable INTEREST_RATE_PERCENTAGE;
  uint256 public immutable FREQUENCY;

  uint256 public immutable DECIMALS;
  uint256 public immutable SCALE;

  uint256 public constant PAR = 1;

  Math.Rounding public constant ROUNDING = Math.Rounding.Floor;

  error PrincipalLessThanScale(uint256 principal, uint256 scale);

  /**
   * @notice Constructor to initialize the SimpleInterest contract with interest rate and frequency.
   * @param interestRatePercentage The annual interest rate as a percentage.
   * @param frequency The number of interest periods in a year.
   * @param decimals The number of decimals for scaling calculations
   */
  constructor(uint256 interestRatePercentage, uint256 frequency, uint256 decimals) {
    INTEREST_RATE_PERCENTAGE = interestRatePercentage;
    FREQUENCY = frequency;
    DECIMALS = decimals;
    SCALE = 10 ** decimals;
  }

  /**
   * @notice Calculates the simple interest based on the principal and elapsed time periods.
   * @param principal The initial principal amount.
   * @param numTimePeriodsElapsed The number of time periods for which interest is calculated.
   * @return interest The calculated interest amount.
   */
  function calcInterest(
    uint256 principal,
    uint256 numTimePeriodsElapsed
  ) public view virtual returns (uint256 interest) {
    if (principal < SCALE) {
      revert PrincipalLessThanScale(principal, SCALE);
    }

    uint256 interestScaled = _calcInterestWithScale(principal, numTimePeriodsElapsed);

    return _unscale(interestScaled);
  }

  /**
   * @notice Internal function to calculate the interest with scaling.
   * @dev This function scales the interest calculation for internal use.
   * @param principal The initial principal amount.
   * @param numTimePeriodsElapsed The number of time periods for which interest is calculated.
   * @return _interestScaled The scaled interest amount.
   */
  function _calcInterestWithScale(
    uint256 principal,
    uint256 numTimePeriodsElapsed
  ) internal view returns (uint256 _interestScaled) {

    uint256 interestScaled = _calcInterestWithScale(principal, numTimePeriodsElapsed, INTEREST_RATE_PERCENTAGE);

    return interestScaled;
  }

  /**
 * @notice Internal function to calculate the interest with scaling.
   * @dev This function scales the interest calculation for internal use.
   * @param principal The initial principal amount.
   * @param numTimePeriodsElapsed The number of time periods for which interest is calculated.
   * @param interestRatePercentage The interest rate as a Percent
   * @return _interestScaled The scaled interest amount.
   */
  function _calcInterestWithScale(
    uint256 principal,
    uint256 numTimePeriodsElapsed,
    uint256 interestRatePercentage
  ) internal view returns (uint256 _interestScaled) {

    uint256 interestScaled = _scale(principal).mulDiv(
      interestRatePercentage * numTimePeriodsElapsed, FREQUENCY * 100, ROUNDING);

    return interestScaled;
  }

  function calcPriceScaled(
    uint256 numTimePeriodsElapsed
  ) public view virtual returns (uint256 interest) {

    uint256 interestScaled = _calcInterestWithScale(PAR, numTimePeriodsElapsed);

    return _scale(PAR) + interestScaled;
  }


  /**
 * @notice Calculates the discounted principal by dividing the principal by the price.
 * @param principal The initial principal amount.
 * @param numTimePeriodsElapsed The number of time periods for which interest is calculated.
 * @return The discounted principal amount.
 */
  function calcDiscounted(uint256 principal, uint256 numTimePeriodsElapsed) public view returns (uint256) {
    if (principal < SCALE) {
      revert PrincipalLessThanScale(principal, SCALE);
    }
    uint256 priceScaled = calcPriceScaled(numTimePeriodsElapsed);

    uint256 discountedScaled = _scale(principal).mulDiv(SCALE, priceScaled, ROUNDING); // Discounted = Principal / Price

    return _unscale(discountedScaled);
  }


  /**
 * @notice Recovers the original principal from a discounted value by multiplying with the price.
 * @param discounted The discounted principal amount.
 * @param numTimePeriodsElapsed The number of time periods for which interest was calculated.
 * @return The recovered original principal amount.
 */
  function calcPrincipalFromDiscounted(uint256 discounted, uint256 numTimePeriodsElapsed) public view virtual returns (uint256) {
    uint256 priceScaled = calcPriceScaled(numTimePeriodsElapsed);

    uint256 principalScaled = _scale(discounted).mulDiv(priceScaled, SCALE, ROUNDING); // Principal = Discounted * Price

    return _unscale(principalScaled);
  }


  /**
   * @notice Internal utility function to unscale the amount.
   * @param amount The scaled amount to be unscaled.
   * @return unscaledAmount The unscaled amount.
   */
  function _unscale(uint256 amount) internal view returns (uint256 unscaledAmount) {
    return amount / SCALE;
  }

  /**
   * @notice Internal utility function to scale the amount.
   * @param amount The unscaled amount to be scaled.
   * @return scaledAmount The scaled amount.
   */
  function _scale(uint256 amount) internal view returns (uint256 scaledAmount) {
    return amount * SCALE;
  }

  /**
   * @notice Returns the frequency of interest application (number of periods in a year).
   * @return frequency The frequency value.
   */
  function getFrequency() public view virtual returns (uint256 frequency) {
    return FREQUENCY;
  }

  /**
   * @notice Returns the annual interest rate as a percentage.
   * @return interestRateInPercentage The interest rate as a percentage.
   */
  function getInterestInPercentage() public view virtual returns (uint256 interestRateInPercentage) {
    return INTEREST_RATE_PERCENTAGE;
  }

  /**
   * @notice Returns the scale factor for internal calculations (e.g., 10^18 for 18 decimals).
   * @return scale The scale factor.
   */
  function getScale() public view virtual returns (uint256 scale) {
    return SCALE;
  }
}
