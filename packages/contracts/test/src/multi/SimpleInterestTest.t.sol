// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { console2 } from "forge-std/console2.sol";
import { Test } from "forge-std/Test.sol";
// import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
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
}

contract LinearPriceTest is Test {
    function test__LinearPriceTest_Annual() public {
        uint256 apy = 3; // APY in percentage
        uint256 oneYear = 1; // 1 is a year

        SimpleInterest simpleInterest = new SimpleInterest(apy, oneYear);

        uint256 principal = 100;
        assertEq(0, simpleInterest.interest(principal, 0));
        assertEq(apy, simpleInterest.interest(principal, 1)); // 1 year
        assertEq(apy * 2, simpleInterest.interest(principal, 2)); // 2 years
    }

    // daily interest of 12% APY (uses 360 day count)
    function test__LinearPriceTest_Daily() public {
        uint256 apy = 12; // 12% APY
        uint256 numberOfDays = 360; // days

        SimpleInterest simpleInterest = new SimpleInterest(apy, numberOfDays);

        uint256 principal = 100;
        assertEq(0, simpleInterest.interest(principal, 0));
        assertEq(1, simpleInterest.interest(principal, 30));
        assertEq(apy / 2, simpleInterest.interest(principal, 180));
        assertEq(apy, simpleInterest.interest(principal, 360));
    }
}
