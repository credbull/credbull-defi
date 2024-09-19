// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title SimpleInterest
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
 * @dev all functions are internal to be deployed in the same contract as caller (not a separate one)
 */
library CalcSimpleInterest {
    using Math for uint256;

    error PrincipalLessThanScale(uint256 principal, uint256 scale);

    struct InterestParams {
        uint256 interestRatePercentScaled;
        uint256 numTimePeriodsElapsed;
        uint256 frequency;
        uint256 scale;
    }

    /// @notice Calculates simple interest using `principal` ...
    /// @dev function is internal to be deployed in the same contract as caller (not a separate one)
    function calcInterest(
        uint256 principal,
        uint256 interestRatePercentScaled,
        uint256 numTimePeriodsElapsed,
        uint256 frequency,
        uint256 scale
    ) internal pure returns (uint256 interest) {
        return principal.mulDiv(
            interestRatePercentScaled * numTimePeriodsElapsed, frequency * scale * 100, Math.Rounding.Floor
        );
    }

    /// @notice Calculates simple interest using `interestParams`
    /// @dev function is internal to be deployed in the same contract as caller (not a separate one)
    function calcInterest(uint256 principal, InterestParams memory interestParams)
        internal
        pure
        returns (uint256 interest)
    {
        return calcInterest(
            principal,
            interestParams.interestRatePercentScaled,
            interestParams.numTimePeriodsElapsed,
            interestParams.frequency,
            interestParams.scale
        );
    }

    /// @notice Calculates the price after `numTimePeriodsElapsed`, scaled.
    /// @notice Price represents the accrued interest over time for a Principal of 1.
    function calcPriceFromInterest(
        uint256 interestRatePercentScaled,
        uint256 numTimePeriodsElapsed,
        uint256 frequency,
        uint256 scale
    ) internal pure returns (uint256 priceScaled) {
        uint256 parScaled = 1 * scale;

        uint256 interest = calcInterest(parScaled, interestRatePercentScaled, numTimePeriodsElapsed, frequency, scale);

        return parScaled + interest;
    }
}
