// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SimpleInterest } from "./SimpleInterest.s.sol";
import { Frequencies } from "./Frequencies.s.sol";

import { Test } from "forge-std/Test.sol";

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
