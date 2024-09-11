// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { ICalcInterestMetadata } from "@credbull-spike/contracts/ian/interfaces/ICalcInterestMetadata.sol";

/**
 * @title SimpleInterest
 * @dev This contract implements the calculation of simple interest
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
 */
contract CalcSimpleInterest is ICalcInterestMetadata {
  using Math for uint256;

  uint256 public immutable INTEREST_RATE; // IR as %, e.g. 15 for 15% (or 0.15)
  uint256 public immutable FREQUENCY;

  uint256 public immutable DECIMALS;
  uint256 public immutable SCALE;

  Math.Rounding public constant ROUNDING = Math.Rounding.Floor;

  error PrincipalLessThanScale(uint256 principal, uint256 scale);

  /**
   * @notice Parameters to for CalcSimpleInterest
   * @param interestRatePercentage The annual interest rate as a percentage.
   * @param frequency The number of interest periods in a year.
   * @param decimals The number of decimals for scaling calculations.
   */
  struct CalcInterestParams {
    uint256 interestRatePercentage;
    uint256 frequency;
    uint256 decimals;
  }

  /**
   * @notice Constructor to initialize the CalcSimpleInterest contract with interest rate, frequency, and scaling parameters.
   * @param calcInterestParams The parameters to construct a CalcSimpleInterest
   */
  constructor(CalcInterestParams memory calcInterestParams) {
    INTEREST_RATE = calcInterestParams.interestRatePercentage;
    FREQUENCY = calcInterestParams.frequency;
    DECIMALS = calcInterestParams.decimals;
    SCALE = 10 ** calcInterestParams.decimals;
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
    return calcInterest(principal, numTimePeriodsElapsed, INTEREST_RATE, FREQUENCY);
  }

  /**
   * @notice Internal function to calculate the interest with scaling applied using the interest rate percentage.
   * @dev - return value is scaled as Interest * SCALE.  For example: Interest=1.01 and Scale=100 returns 101
   * @param principal The initial principal amount.
   * @param numTimePeriodsElapsed The number of time periods for which interest is calculated.
   * @param interestRatePercentage The interest rate as a percentage.
   * @param frequency The frequency of interest application
   * @return interestScaled The scaled interest amount.
   */
  function calcInterest(
    uint256 principal,
    uint256 numTimePeriodsElapsed,
    uint256 interestRatePercentage,
    uint256 frequency
  ) public view returns (uint256 interestScaled) {
    if (principal < SCALE) {
      revert PrincipalLessThanScale(principal, SCALE);
    }

    uint256 _interestScaled =
      _scale(principal).mulDiv(interestRatePercentage * numTimePeriodsElapsed, frequency * 100, ROUNDING);

    return _unscale(_interestScaled);
  }

  /**
   * @notice Internal function to calculate the interest with scaling applied using the interest rate percentage.
   * @dev - return value is scaled as Interest * SCALE.  For example: Interest=1.01 and Scale=100 returns 101
   * @param principal The initial principal amount.
   * @param numTimePeriodsElapsed The number of time periods for which interest is calculated.
   * @param interestRatePercentage The interest rate as a percentage.
   * @param frequency The frequency of interest application
   * @return interestScaled The scaled interest amount.
   */
  function _calcInterestWithScale(
    uint256 principal,
    uint256 numTimePeriodsElapsed,
    uint256 interestRatePercentage,
    uint256 frequency
  ) internal view returns (uint256 interestScaled) {
    uint256 _interestScaled =
      _scale(principal).mulDiv(interestRatePercentage * numTimePeriodsElapsed, frequency * 100, ROUNDING);

    return _interestScaled;
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
    return INTEREST_RATE;
  }

  /**
   * @notice Returns the scale factor for internal calculations (e.g., 10^18 for 18 decimals).
   * @return scale The scale factor.
   */
  function getScale() public view virtual returns (uint256 scale) {
    return SCALE;
  }
}
