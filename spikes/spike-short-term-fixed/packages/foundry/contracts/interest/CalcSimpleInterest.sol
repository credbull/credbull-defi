// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { ICalcInterestMetadata } from "@credbull-contracts/contracts/interest/ICalcInterestMetadata.sol";

/**
 * @title SimpleInterest
 * @dev This library implements the calculation of simple interest
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
library CalcSimpleInterest {
  using Math for uint256;

  error PrincipalLessThanScale(uint256 principal, uint256 scale);

  /**
   * @notice calculate the interest with scaling applied using the interest rate percentage.
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
  ) public pure returns (uint256 interestScaled) {
    uint256 principalScaled = _scale(principal);

    uint256 _interestScaled = _calcInterestWithScale(principalScaled, numTimePeriodsElapsed, interestRatePercentage, frequency);

    return _unscale(_unscale(_interestScaled));
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
  ) public pure returns (uint256 interestScaled) {
    if (principal < getScale()) {
      revert PrincipalLessThanScale(principal, getScale());
    }

    uint256 _interestScaled =
      _scale(principal).mulDiv(interestRatePercentage * numTimePeriodsElapsed, frequency * 100, Math.Rounding.Floor);

    return _interestScaled;
  }

  /**
   * @notice Internal utility function to unscale the amount.
   * @param amount The scaled amount to be unscaled.
   * @return unscaledAmount The unscaled amount.
   */
  function _unscale(uint256 amount) internal pure returns (uint256 unscaledAmount) {
    return amount / getScale();
  }

  /**
   * @notice Internal utility function to scale the amount.
   * @param amount The unscaled amount to be scaled.
   * @return scaledAmount The scaled amount.
   */
  function _scale(uint256 amount) internal pure returns (uint256 scaledAmount) {
    return amount * getScale();
  }


  /**
   * @notice Returns the scale factor for internal calculations (e.g., 10^18 for 18 decimals).
   * @return scale The scale factor.
   */
  function getScale() public pure returns (uint256 scale) {
    return 1e18;
  }
}
