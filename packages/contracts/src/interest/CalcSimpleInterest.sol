// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

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
 * @dev all functions are internal to be deployed in the same contract as caller (not a separate one)
 */
library CalcSimpleInterest {
    using Math for uint256;

    error PrincipalLessThanScale(uint256 principal, uint256 scale);

    struct InterestParams {
        uint256 numTimePeriodsElapsed;
        uint256 interestRatePercentage;
        uint256 frequency;
    }

    /**
     * @notice Calculate SimpleInterest (without compounding)
     * @param principal The initial principal amount.
     * @param numTimePeriodsElapsed The number of time periods for which interest is calculated.
     * @param interestRatePercentage The interest rate as a percentage.
     * @param frequency The frequency of interest application
     * @return interest The interest amount.
     *
     * @dev function is internal to be deployed in the same contract as caller (not a separate one)
     */
    function calcInterest(
        uint256 principal,
        uint256 numTimePeriodsElapsed,
        uint256 interestRatePercentage,
        uint256 frequency
    ) internal pure returns (uint256 interest) {
        uint256 _interest =
            principal.mulDiv(interestRatePercentage * numTimePeriodsElapsed, frequency * 100, Math.Rounding.Floor);

        return _interest;
    }

    /**
     * @notice Calculate SimpleInterest (without compounding)
     * @param interestParams The parameters to the Simple Interest calculation
     * @return interest The interest amount.
     *
     * @dev function is internal to be deployed in the same contract as caller (not a separate one)
     */
    function calcInterest(uint256 principal, InterestParams memory interestParams)
        internal
        pure
        returns (uint256 interest)
    {
        return calcInterest(
            principal,
            interestParams.numTimePeriodsElapsed,
            interestParams.interestRatePercentage,
            interestParams.frequency
        );
    }

    /**
     * @notice Calculates the price for a given number of periods elapsed.
     * Price represents the accrued interest over time for a Principal of 1.
     * @dev - return value is scaled as Price * SCALE.  For example: Price=1.01 and Scale=100 returns 101
     * @param numTimePeriodsElapsed The number of time periods that have elapsed.
     * @return priceScaled The price scaled by the internal scale factor.
     */
    function calcPriceFromInterest(
        uint256 numTimePeriodsElapsed,
        uint256 interestRatePercentage,
        uint256 frequency,
        uint256 scale
    ) internal pure returns (uint256 priceScaled) {
        uint256 parScaled = 1 * scale;

        uint256 interest = calcInterest(parScaled, numTimePeriodsElapsed, interestRatePercentage, frequency);

        return parScaled + interest;
    }
}
