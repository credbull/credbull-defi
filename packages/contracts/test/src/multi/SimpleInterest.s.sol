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
 * - f is the frequency of applying interest
 */
contract SimpleInterest {
    using Math for uint256;

    uint256 public immutable INTEREST_RATE;
    uint256 public immutable FREQUENCY;

    uint256 public constant DECIMALS = 2;
    uint256 public constant SCALE = 10 ** DECIMALS;

    constructor(uint256 interestRatePercentage, uint256 frequency) {
        INTEREST_RATE = interestRatePercentage;
        FREQUENCY = frequency * SCALE;
    }

    // Interest = (IR * P * m) / f
    function interest(uint256 principal, uint256 timePeriods) public view returns (uint256) {
        uint256 principalScaled = principal * SCALE;

        uint256 numerator = INTEREST_RATE * principalScaled * timePeriods;

        uint256 simpleInterest = numerator / (FREQUENCY * SCALE);

        console2.log(
            string.concat(
                "(IR * P * m) / f = ",
                Strings.toString(INTEREST_RATE),
                " * ",
                Strings.toString(principalScaled),
                " * ",
                Strings.toString(timePeriods),
                " / ",
                Strings.toString(FREQUENCY),
                " = ",
                Strings.toString(simpleInterest)
            )
        );

        return simpleInterest;
    }

    // P = Discounted / (1 - ((IR * m) / f))
    function principalFromDiscounted(uint256 discounted, uint256 timePeriods) public view returns (uint256) {
        uint256 interestFactor = INTEREST_RATE.mulDiv(timePeriods * SCALE, FREQUENCY); // interest rate times the number of periods (IR * m / f)

        uint256 denominator = (1 * SCALE) - interestFactor; // (1 - interestFactor)

        uint256 principal = discounted.mulDiv(SCALE, denominator);

        console2.log(
            string.concat(
                "Discounted / (1 - ((IR * m) / f)) = ",
                Strings.toString(discounted),
                " / (1 - ((",
                Strings.toString(INTEREST_RATE),
                " * ",
                Strings.toString(timePeriods),
                " ) / ",
                Strings.toString(FREQUENCY),
                " = ",
                Strings.toString(principal)
            )
        );

        return principal;
    }
}
