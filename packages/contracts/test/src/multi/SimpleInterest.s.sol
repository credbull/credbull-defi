// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Tenors } from "./Tenors.s.sol";

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { console2 } from "forge-std/console2.sol";

/**
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
 */
contract SimpleInterest {
    using Math for uint256;

    uint256 public immutable INTEREST_RATE_PERCENTAGE; // in percentage terms 100 = 1
    Tenors.Tenor public immutable FREQUENCY;

    uint256 public constant DECIMALS = 18;
    uint256 public constant SCALE = 10 ** DECIMALS;

    constructor(uint256 interestRatePercentage, Tenors.Tenor frequency) {
        INTEREST_RATE_PERCENTAGE = interestRatePercentage;
        FREQUENCY = frequency;
    }

    // Interest = (IR * P * m) / f
    function calcInterest(uint256 principal, uint256 numTimePeriodsElapsed) public view returns (uint256) {
        uint256 interestScaled = calcInterestScaleDecimals(principal, numTimePeriodsElapsed);

        uint256 interest = interestScaled / SCALE;

        console2.log(
            string.concat(
                "interest = interestScaled / SCALE ",
                Strings.toString(interestScaled),
                " / ",
                Strings.toString(SCALE),
                " = ",
                Strings.toString(interest)
            )
        );

        return interest;
    }

    // Interest = (IR * P * m) / f
    function calcInterestScaleDecimals(uint256 principal, uint256 numTimePeriodsElapsed)
        public
        view
        returns (uint256)
    {
        uint256 interestScaled =
            principal.mulDiv(INTEREST_RATE_PERCENTAGE * numTimePeriodsElapsed * SCALE, frequencyValue() * 100); // divide by 100 to convert IR to decimal

        console2.log(
            string.concat(
                "(IR * P * m) / f = ",
                Strings.toString(INTEREST_RATE_PERCENTAGE),
                "% * ",
                Strings.toString(principal),
                " * ",
                Strings.toString(numTimePeriodsElapsed),
                " / ",
                Strings.toString(frequencyValue()),
                " = ",
                Strings.toString(interestScaled)
            )
        );

        return interestScaled;
    }

    // P = Discounted / (1 - ((IR * m) / f))
    // NB - the discount is scaled already here !!!
    function calcPrincipalFromDiscountedScaledScaleDecimals(uint256 discounted, uint256 numTimePeriodsElapsed)
        public
        view
        returns (uint256)
    {
        uint256 interestFactor = INTEREST_RATE_PERCENTAGE.mulDiv(numTimePeriodsElapsed * SCALE, frequencyValue() * 100); // interestRate *  numPerods / frequency (IR * m / f) // divide that by 100 to convert IR to decimal

        uint256 denominator = (1 * SCALE) - interestFactor; // (1 - interestFactor)

        uint256 principal = discounted.mulDiv(SCALE, denominator);

        console2.log(
            string.concat(
                "Discounted / (1 - ((IR * m) / f)) = ",
                Strings.toString(discounted),
                " / (1 - ((",
                Strings.toString(INTEREST_RATE_PERCENTAGE),
                " * ",
                Strings.toString(numTimePeriodsElapsed),
                " ) / ",
                Strings.toString(frequencyValue()),
                " = ",
                Strings.toString(principal)
            )
        );

        return principal;
    }

    // P = Discounted / (1 - ((IR * m) / f))
    function calcPrincipalFromDiscounted(uint256 discounted, uint256 numTimePeriodsElapsed)
        public
        view
        returns (uint256)
    {
        uint256 principalFromDiscountedScaled =
            calcPrincipalFromDiscountedScaledScaleDecimals(discounted * SCALE, numTimePeriodsElapsed);

        uint256 principal = principalFromDiscountedScaled / SCALE;

        console2.log(
            string.concat(
                "principal = principalFromDiscountedScaled / SCALE ",
                Strings.toString(principalFromDiscountedScaled),
                " / ",
                Strings.toString(SCALE),
                " = ",
                Strings.toString(principal)
            )
        );

        return principal;
    }

    function frequencyValue() public view returns (uint256) {
        return Tenors.toValue(FREQUENCY);
    }
}
