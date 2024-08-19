// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SimpleInterest } from "./SimpleInterest.s.sol";
import { Tenors } from "./Tenors.s.sol";

import { Test } from "forge-std/Test.sol";

contract SimpleInterestTest is Test {
    using Math for uint256;

    function test__SimpleInterestTest__InterestAnnual() public {
        uint256 apy = 3; // APY in percentage

        SimpleInterest simpleInterest = new SimpleInterest(apy, Tenors.Tenor.YEARS_ONE);

        uint256 principal = 500;
        assertEq(0, simpleInterest.calcInterest(principal, 0), "wrong interest at year 0");
        assertEq(principal.mulDiv(apy, 100), simpleInterest.calcInterest(principal, 1), "wrong interest at year 1"); // 1 year
        assertEq(principal.mulDiv(apy * 2, 100), simpleInterest.calcInterest(principal, 2), "wrong interest at year 2"); // 2 years
    }

    function test__SimpleInterestTest__DiscountingAnnual() public {
        uint256 apy = 10; // APY in percentage

        SimpleInterest simpleInterest = new SimpleInterest(apy, Tenors.Tenor.YEARS_ONE);

        uint256 principal = 500;
        assertEq(
            principal,
            simpleInterest.calcPrincipalFromDiscounted(principal, 0),
            "wrong principal from discounted at year 0"
        );

        uint256 discountedYearOne = principal - simpleInterest.calcInterest(principal, 1);
        assertEq(
            principal,
            simpleInterest.calcPrincipalFromDiscounted(discountedYearOne, 1),
            "wrong principal from discounted at year 1"
        );

        uint256 discountedYearTwo = principal - 2 * (simpleInterest.calcInterest(principal, 1));
        assertEq(
            principal,
            simpleInterest.calcPrincipalFromDiscounted(discountedYearTwo, 2),
            "wrong principal from discounted at year 2"
        );

        uint256 discountedYearThree = principal - 3 * (simpleInterest.calcInterest(principal, 1));
        assertEq(
            principal,
            simpleInterest.calcPrincipalFromDiscounted(discountedYearThree, 3),
            "wrong principal from discounted at year 3"
        );
    }

    // daily interest of 12% APY (uses 360 day count)
    function test__SimpleInterestTest__InterestDaily() public {
        uint256 apy = 12; // 12% APY

        SimpleInterest simpleInterest = new SimpleInterest(apy, Tenors.Tenor.DAYS_360);
        uint256 numberOfDays = simpleInterest.frequencyValue();

        uint256 principal = 400;
        assertEq(0, simpleInterest.calcInterest(principal, 0), "wrong interest at day 0");

        assertEq(
            principal.mulDiv(apy / (numberOfDays / 30), 100),
            simpleInterest.calcInterest(principal, 30),
            "wrong interest at day 30"
        );
        assertEq(
            principal.mulDiv(apy / 2, 100),
            simpleInterest.calcInterest(principal, numberOfDays / 2),
            "wrong interest at day 180"
        );

        assertEq(
            principal.mulDiv(apy, 100),
            simpleInterest.calcInterest(principal, numberOfDays),
            "wrong interest at day 360"
        );
    }

    // daily interest of 12% APY (uses 30 day count)
    // using the scaled up version for results that are fractional
    function test__SimpleInterestTest__InterestDailyScaled() public {
        uint256 apy = 12; // 12% APY
        SimpleInterest simpleInterest = new SimpleInterest(apy, Tenors.Tenor.DAYS_30);

        uint256 principal = 50;
        uint256 SCALE = simpleInterest.SCALE();

        assertEq(0 * SCALE, simpleInterest.calcInterestScaleDecimals(principal, 0), "wrong interestScaled at day 0");

        // unscaledInterest = 50 * 0.12 * 1 / 30 = 6 / 30 = 0.2
        uint256 twoTenthsScaled = SCALE.mulDiv(2, 10);
        assertEq(
            twoTenthsScaled, simpleInterest.calcInterestScaleDecimals(principal, 1), "wrong interestScaled at day 1"
        );
    }

    function test__SimpleInterestTest__DiscountingDaily() public {
        uint256 apy = 12; // APY in percentage

        SimpleInterest simpleInterest = new SimpleInterest(apy, Tenors.Tenor.DAYS_365);
        uint256 numberOfDays = simpleInterest.frequencyValue();

        uint256 principal = 400;
        assertEq(
            principal, simpleInterest.calcPrincipalFromDiscounted(principal, 0), "wrong principal from discounted at 0"
        );

        uint256 discountedFullTerm = principal - simpleInterest.calcInterest(principal, numberOfDays);
        assertEq(
            principal,
            simpleInterest.calcPrincipalFromDiscounted(discountedFullTerm, numberOfDays),
            "wrong principal from discounted at full term"
        );

        uint256 oneFifthTerm = numberOfDays / 5; // 365 / 5 = 73 days
        uint256 discountedOneFifthTerm = principal - simpleInterest.calcInterest(principal, oneFifthTerm);
        assertEq(
            principal,
            simpleInterest.calcPrincipalFromDiscounted(discountedOneFifthTerm, oneFifthTerm),
            "wrong principal from discounted at oneFifth term (365/5 = 73 days)"
        );

        uint256 oneDay = 1;
        uint256 discountedOneDay = principal - simpleInterest.calcInterest(principal, oneDay);
        assertEq(
            principal,
            simpleInterest.calcPrincipalFromDiscounted(discountedOneDay, oneDay),
            "wrong principal from discounted at one day"
        );

        uint256 threeDays = 3;
        uint256 discountedThreeDays = principal - simpleInterest.calcInterest(principal, threeDays);
        assertEq(
            principal,
            simpleInterest.calcPrincipalFromDiscounted(discountedThreeDays, threeDays),
            "wrong principal from discounted at three days"
        );

        uint256 thirtyDays = 30;
        uint256 discountedThirtyDays = principal - simpleInterest.calcInterest(principal, thirtyDays);
        assertEq(
            principal,
            simpleInterest.calcPrincipalFromDiscounted(discountedThirtyDays, thirtyDays),
            "wrong principal from discounted at thirty days"
        );
    }

    // daily interest of 12% APY (uses 30 day count)
    // using the scaled up version for results that are fractional
    function test__SimpleInterestTest__DiscountDailyScaled() public {
        uint256 apy = 10; // 10% APY

        SimpleInterest simpleInterest = new SimpleInterest(apy, Tenors.Tenor.DAYS_365);
        uint256 numberOfDays = simpleInterest.frequencyValue();

        uint256 principal = 400;
        uint256 SCALE = simpleInterest.SCALE();

        assertEq(
            principal * SCALE,
            simpleInterest.calcPrincipalFromDiscountedScaledScaleDecimals(principal * SCALE, 0),
            "wrong principalScaled from discounted at 0"
        );

        uint256 discountedFullTerm =
            principal * SCALE - simpleInterest.calcInterestScaleDecimals(principal, numberOfDays);
        assertEq(
            principal * SCALE,
            simpleInterest.calcPrincipalFromDiscountedScaledScaleDecimals(discountedFullTerm, numberOfDays),
            "wrong principalScaled at full term"
        );

        uint256 discountedScaledOneDay = principal * SCALE - simpleInterest.calcInterestScaleDecimals(principal, 1);
        assertApproxEqAbs(
            principal * SCALE,
            simpleInterest.calcPrincipalFromDiscountedScaledScaleDecimals(discountedScaledOneDay, 1),
            100, // with 18 decimals, means allowed difference of 1E+16
            "wrong principalScaled at day 1"
        );
    }
}
