// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { Frequencies } from "./Frequencies.s.sol";

import { Test } from "forge-std/Test.sol";
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

contract SimpleInterestTest is Test {
    using Math for uint256;

    function test__SimpleInterestTest_Interest_Annual() public {
        uint256 apy = 3; // APY in percentage
        uint256 oneYear = 1; // 1 is a year

        SimpleInterest simpleInterest = new SimpleInterest(apy, oneYear);

        uint256 principal = 500;
        assertEq(0, simpleInterest.interest(principal, 0), "wrong interest at year 0");
        assertEq(principal.mulDiv(apy, 100), simpleInterest.interest(principal, 1), "wrong interest at year 1"); // 1 year
        assertEq(principal.mulDiv(apy * 2, 100), simpleInterest.interest(principal, 2), "wrong interest at year 2"); // 2 years

        uint256 discounted = principal - simpleInterest.interest(principal, 1);
        assertEq(
            principal,
            simpleInterest.principalFromDiscounted(discounted, 1),
            "wrong principal from discounted at year 1"
        );
    }

    function test__SimpleInterestTest_Discounting_Annual() public {
        uint256 apy = 10; // APY in percentage
        uint256 oneYear = 1; // 1 is a year

        SimpleInterest simpleInterest = new SimpleInterest(apy, oneYear);

        uint256 principal = 500;
        assertEq(
            principal, simpleInterest.principalFromDiscounted(principal, 0), "wrong principal from discounted at year 0"
        );
        assertEq(principal, simpleInterest.principalFromDiscounted(500, 0), "wrong principal from discounted at year 0");

        assertEq(
            principal, simpleInterest.principalFromDiscounted(450, 1), "wrong principal from discounted at year 1 (b)"
        );

        uint256 discountedYearOne = principal - simpleInterest.interest(principal, 1);
        assertEq(
            principal,
            simpleInterest.principalFromDiscounted(discountedYearOne, 1),
            "wrong principal from discounted at year 1 (a)"
        );

        uint256 discountedYearTwo = principal - 2 * (simpleInterest.interest(principal, 1));
        assertEq(
            principal,
            simpleInterest.principalFromDiscounted(discountedYearTwo, 2),
            "wrong principal from discounted at year 2"
        );
        assertEq(principal, simpleInterest.principalFromDiscounted(400, 2), "wrong principal from discounted at year 2");

        uint256 discountedYearThree = principal - 3 * (simpleInterest.interest(principal, 1));
        assertEq(
            principal,
            simpleInterest.principalFromDiscounted(discountedYearThree, 3),
            "wrong principal from discounted at year 3"
        );
        assertEq(principal, simpleInterest.principalFromDiscounted(350, 3), "wrong principal from discounted at year 3");
    }

    // daily interest of 12% APY (uses 360 day count)
    function test__SimpleInterestTest_Interest_Daily() public {
        uint256 apy = 12; // 12% APY
        uint256 numberOfDays = Frequencies.DAYS_360; // days

        SimpleInterest simpleInterest = new SimpleInterest(apy, numberOfDays);

        uint256 principal = 400;
        assertEq(0, simpleInterest.interest(principal, 0), "wrong interest at day 0");

        assertEq(
            principal.mulDiv(apy / (numberOfDays / Frequencies.DAYS_30), 100),
            simpleInterest.interest(principal, Frequencies.DAYS_30),
            "wrong interest at day 30"
        );
        assertEq(
            principal.mulDiv(apy / 2, 100),
            simpleInterest.interest(principal, numberOfDays / 2),
            "wrong interest at day 180"
        );

        assertEq(
            principal.mulDiv(apy, 100), simpleInterest.interest(principal, numberOfDays), "wrong interest at day 360"
        );
    }

    function test__SimpleInterestTest_Discounting_Daily() public {
        uint256 apy = 12; // APY in percentage
        uint256 numberOfDays = Frequencies.DAYS_360; // days

        SimpleInterest simpleInterest = new SimpleInterest(apy, numberOfDays);

        uint256 principal = 100;
        assertEq(
            principal, simpleInterest.principalFromDiscounted(principal, 0), "wrong principal from discounted at 0"
        );
        assertEq(
            principal, simpleInterest.principalFromDiscounted(principal, 0), "wrong principal from discounted at 0"
        );

        uint256 discountedFullTerm = principal - simpleInterest.interest(principal, numberOfDays);
        assertEq(
            principal,
            simpleInterest.principalFromDiscounted(discountedFullTerm, numberOfDays),
            "wrong principal from discounted at full term"
        );

        uint256 halfTerm = numberOfDays / 2;
        uint256 discountedHalfTerm = principal - simpleInterest.interest(principal, halfTerm);
        assertEq(
            principal,
            simpleInterest.principalFromDiscounted(discountedHalfTerm, halfTerm),
            "wrong principal from discounted at half term"
        );

        uint256 oneDay = 1;
        uint256 discountedOneDay = principal - simpleInterest.interest(principal, oneDay);
        assertEq(
            principal,
            simpleInterest.principalFromDiscounted(discountedOneDay, oneDay),
            "wrong principal from discounted at one day"
        );

        uint256 threeDays = 3;
        uint256 discountedThreeDays = principal - simpleInterest.interest(principal, threeDays);
        assertEq(
            principal,
            simpleInterest.principalFromDiscounted(discountedThreeDays, threeDays),
            "wrong principal from discounted at three days"
        );

        uint256 thirtyDays = 30;
        uint256 discountedThirtyDays = principal - simpleInterest.interest(principal, thirtyDays);
        assertEq(
            principal,
            simpleInterest.principalFromDiscounted(discountedThirtyDays, thirtyDays),
            "wrong principal from discounted at thirty days"
        );
    }
}
