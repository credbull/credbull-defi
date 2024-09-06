// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { ISimpleInterest } from "@credbull-spike/contracts/ian/interfaces/ISimpleInterest.sol";

/**
 * @title SimpleInterest
 * @dev This contract implements the calculation of simple interest, discounted principal, and recovery of the original principal using the Price mechanism.
 *
 * Simple interest is calculated on the principal amount, excluding compounding.
 * The Price reflects the interest accrued over time for a Principal of 1.
 *
 * Formula: (IR * P * m) / f
 * - IR: Annual interest rate
 * - P: Principal amount
 * - m: Number of periods elapsed
 * - f: Frequency of interest application
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
   * @notice Constructor to initialize the SimpleInterest contract with interest rate, frequency, and scaling parameters.
   * @param interestRatePercentage The annual interest rate as a percentage.
   * @param frequency The number of interest periods in a year.
   * @param decimals The number of decimals for scaling calculations.
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
   * @notice Internal function to calculate the interest with scaling applied.
   * @param principal The initial principal amount.
   * @param numTimePeriodsElapsed The number of time periods for which interest is calculated.
   * @return interestScaled The scaled interest amount.
   */
  function _calcInterestWithScale(
    uint256 principal,
    uint256 numTimePeriodsElapsed
  ) internal view returns (uint256 interestScaled) {

    uint256 _interestScaled = _calcInterestWithScale(principal, numTimePeriodsElapsed, INTEREST_RATE_PERCENTAGE);

    return _interestScaled;
  }

  /**
   * @notice Internal function to calculate the interest with scaling applied using the interest rate percentage.
   * @param principal The initial principal amount.
   * @param numTimePeriodsElapsed The number of time periods for which interest is calculated.
   * @param interestRatePercentage The interest rate as a percentage.
   * @return interestScaled The scaled interest amount.
   */
  function _calcInterestWithScale(
    uint256 principal,
    uint256 numTimePeriodsElapsed,
    uint256 interestRatePercentage
  ) internal view returns (uint256 interestScaled) {

    uint256 _interestScaled = _scale(principal).mulDiv(
      interestRatePercentage * numTimePeriodsElapsed, FREQUENCY * 100, ROUNDING);

    return _interestScaled;
  }

  /**
   * @notice Calculates the price for a given number of periods elapsed.
   * Price represents the accrued interest over time for a Principal of 1.
   * @param numTimePeriodsElapsed The number of time periods that have elapsed.
   * @return priceScaled The price scaled by the internal scale factor.
   */
  function calcPriceScaled(
    uint256 numTimePeriodsElapsed
  ) public view virtual returns (uint256 priceScaled) {

    uint256 interestScaled = _calcInterestWithScale(PAR, numTimePeriodsElapsed);

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
    uint256 priceScaled = calcPriceScaled(numTimePeriodsElapsed);

    uint256 discountedScaled = _scale(principal).mulDiv(SCALE, priceScaled, ROUNDING); // Discounted = Principal / Price

    return _unscale(discountedScaled);
  }

  /**
   * @notice Recovers the original principal from a discounted value by multiplying it with the price.
   * @param discounted The discounted principal amount.
   * @param numTimePeriodsElapsed The number of time periods for which interest was calculated.
   * @return principal The recovered original principal amount.
   */
  function calcPrincipalFromDiscounted(uint256 discounted, uint256 numTimePeriodsElapsed) public view virtual returns (uint256 principal) {
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
