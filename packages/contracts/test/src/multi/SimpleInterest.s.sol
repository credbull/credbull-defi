// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

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

    uint256 public immutable INTEREST_RATE_PERCENTAGE;
    uint256 public immutable FREQUENCY;

    uint256 public constant DECIMALS = 18;
    uint256 public constant SCALE = 10 ** DECIMALS;

    Math.Rounding public constant ROUNDING = Math.Rounding.Floor;

    constructor(uint256 interestRatePercentage, uint256 frequency) {
        INTEREST_RATE_PERCENTAGE = interestRatePercentage;
        FREQUENCY = frequency;
    }

    function calcInterest(uint256 principal, uint256 numTimePeriodsElapsed) public view returns (uint256) {
        uint256 interestScaled = _calcInterestWithScale(principal, numTimePeriodsElapsed);

        return unscaleAmount(interestScaled);
    }

    function _calcInterestWithScale(uint256 principal, uint256 numTimePeriodsElapsed) internal view returns (uint256) {
        uint256 interestScaled =
            principal.mulDiv(INTEREST_RATE_PERCENTAGE * numTimePeriodsElapsed * SCALE, FREQUENCY * 100, ROUNDING);

        console2.log(
            string.concat(
                "(IR * P * m) / f = ",
                Strings.toString(INTEREST_RATE_PERCENTAGE),
                "% * ",
                Strings.toString(principal),
                " * ",
                Strings.toString(numTimePeriodsElapsed),
                " / ",
                Strings.toString(FREQUENCY),
                " = ",
                Strings.toString(interestScaled)
            )
        );

        return interestScaled;
    }

    function calcPrincipalFromDiscounted(uint256 discounted, uint256 numTimePeriodsElapsed)
        public
        view
        returns (uint256)
    {
        uint256 scaledPrincipal = _calcPrincipalFromDiscountedWithScale(scaleAmount(discounted), numTimePeriodsElapsed);

        return unscaleAmount(scaledPrincipal);
    }

    function _calcPrincipalFromDiscountedWithScale(uint256 discounted, uint256 numTimePeriodsElapsed)
        internal
        view
        returns (uint256)
    {
        uint256 interestFactor =
            INTEREST_RATE_PERCENTAGE.mulDiv(numTimePeriodsElapsed * SCALE, FREQUENCY * 100, ROUNDING);

        uint256 principal = discounted.mulDiv(SCALE, SCALE - interestFactor, ROUNDING);

        console2.log(
            string.concat(
                "Principal = Discounted / (1 - ((IR * m) / f)) = ",
                Strings.toString(discounted),
                " / (1 - ((",
                Strings.toString(INTEREST_RATE_PERCENTAGE),
                " * ",
                Strings.toString(numTimePeriodsElapsed),
                " ) / ",
                Strings.toString(FREQUENCY),
                " = ",
                Strings.toString(principal)
            )
        );

        return principal;
    }

    function scaleAmount(uint256 amount) internal pure returns (uint256) {
        return amount * SCALE;
    }

    function unscaleAmount(uint256 amount) internal pure returns (uint256) {
        return amount / SCALE;
    }
}
