// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { console2 } from "forge-std/console2.sol";
import { Test } from "forge-std/Test.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

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

    function principalFromDiscounted(uint256 discounted, uint256 timePeriods) public view returns (uint256) {
        uint256 discountFactor = INTEREST_RATE * timePeriods; // interest over periods = eg. 3% * 2 = 6%
        uint256 denominator = 100 - discountFactor; // 100% - 3% = 97%
        uint256 principal = discounted.mulDiv(100, denominator); // discounted * 100 / 97

        return principal;
    }
}

contract LinearPriceTest is Test {
    using Math for uint256;

    function test__LinearPriceTest_Interest_Annual() public {
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

    function test__LinearPriceTest_Discounting_Annual() public {
        uint256 apy = 10; // APY in percentage
        uint256 oneYear = 1; // 1 is a year

        SimpleInterest simpleInterest = new SimpleInterest(apy, oneYear);

        uint256 principal = 500;
        assertEq(
            principal, simpleInterest.principalFromDiscounted(principal, 0), "wrong principal from discounted at year 0"
        );
        assertEq(principal, simpleInterest.principalFromDiscounted(500, 0), "wrong principal from discounted at year 0");

        uint256 discountedYearOne = principal - simpleInterest.interest(principal, 1);
        assertEq(
            principal,
            simpleInterest.principalFromDiscounted(discountedYearOne, 1),
            "wrong principal from discounted at year 1"
        );
        assertEq(principal, simpleInterest.principalFromDiscounted(450, 1), "wrong principal from discounted at year 1");

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
    function test__LinearPriceTest_Interest_Daily() public {
        uint256 apy = 12; // 12% APY
        uint256 numberOfDays = 360; // days

        SimpleInterest simpleInterest = new SimpleInterest(apy, numberOfDays);

        uint256 principal = 400;
        assertEq(0, simpleInterest.interest(principal, 0), "wrong interest at day 0");
        assertEq(
            principal.mulDiv(apy / (numberOfDays / 30), 100),
            simpleInterest.interest(principal, 30),
            "wrong interest at day 30"
        );
        assertEq(principal.mulDiv(apy / 2, 100), simpleInterest.interest(principal, 180), "wrong interest at day 180");
        assertEq(principal.mulDiv(apy, 100), simpleInterest.interest(principal, 360), "wrong interest at day 360");
    }
}
