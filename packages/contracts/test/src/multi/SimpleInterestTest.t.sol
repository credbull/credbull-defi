// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SimpleInterest } from "./SimpleInterest.s.sol";
import { Frequencies } from "./Frequencies.s.sol";

import { Test } from "forge-std/Test.sol";

contract SimpleInterestTest is Test {
    using Math for uint256;

    function test__SimpleInterestTest__InterestMonthly() public {
        uint256 apy = 12; // APY in percentage

        uint256 monthlyFrequency = Frequencies.toValue(Frequencies.Frequency.MONTHLY);
        SimpleInterest simpleInterest = new SimpleInterest(apy, monthlyFrequency);

        uint256 principal = 500;
        assertEq(0, simpleInterest.calcInterest(principal, 0), "wrong interest at month 0");
        assertEq(
            principal.mulDiv(apy / 12, 100), simpleInterest.calcInterest(principal, 1), "wrong interest at month 1"
        );
        assertEq(principal.mulDiv(apy / 6, 100), simpleInterest.calcInterest(principal, 2), "wrong interest at month 2");

        assertEq(principal.mulDiv(apy, 100), simpleInterest.calcInterest(principal, 12), "wrong interest at month 12");

        assertEq(
            principal.mulDiv(2 * apy, 100), simpleInterest.calcInterest(principal, 24), "wrong interest at month 24"
        );
    }

    function test__SimpleInterestTest__DiscountingMonthly() public {
        uint256 apy = 12; // APY in percentage
        uint256 monthlyFrequency = Frequencies.toValue(Frequencies.Frequency.MONTHLY);
        SimpleInterest simpleInterest = new SimpleInterest(apy, monthlyFrequency);

        uint256 principal = 500;
        assertEq(
            principal,
            simpleInterest.calcPrincipalFromDiscounted(principal, 0),
            "wrong principal from discounted at month 0"
        );

        uint256 discountedMonthOne = principal - simpleInterest.calcInterest(principal, 1);
        assertEq(
            principal,
            simpleInterest.calcPrincipalFromDiscounted(discountedMonthOne, 1),
            "wrong principal from discountedMonthOne"
        );

        uint256 discountedMonthTwo = principal - 2 * (simpleInterest.calcInterest(principal, 1));
        assertEq(
            principal,
            simpleInterest.calcPrincipalFromDiscounted(discountedMonthTwo, 2),
            "wrong principal from discountedMonthTwo"
        );

        uint256 discountedMonthThree = principal - 3 * (simpleInterest.calcInterest(principal, 1));
        assertEq(
            principal,
            simpleInterest.calcPrincipalFromDiscounted(discountedMonthThree, 3),
            "wrong principal from discountedMonthThree"
        );

        uint256 discountedMonthTwelve = principal - 12 * (simpleInterest.calcInterest(principal, 1));
        assertEq(
            principal,
            simpleInterest.calcPrincipalFromDiscounted(discountedMonthTwelve, 12),
            "wrong principal from discountedMonthTwelve"
        );

        uint256 discountedMonthTwentyFour = principal - 24 * (simpleInterest.calcInterest(principal, 1));
        assertEq(
            principal,
            simpleInterest.calcPrincipalFromDiscounted(discountedMonthTwentyFour, 24),
            "wrong principal from discountedMonthTwentyFour"
        );
    }

    // daily interest of 12% APY (uses 360 day count)
    function test__SimpleInterestTest__InterestDaily() public {
        uint256 apy = 12; // 12% APY
        uint256 dailyFrequency = Frequencies.toValue(Frequencies.Frequency.DAYS_360);
        SimpleInterest simpleInterest = new SimpleInterest(apy, dailyFrequency);

        uint256 principal = 400;
        assertEq(0, simpleInterest.calcInterest(principal, 0), "wrong interest at day 0");

        assertEq(
            principal.mulDiv(apy / (dailyFrequency / 30), 100),
            simpleInterest.calcInterest(principal, 30),
            "wrong interest at day 30"
        );
        assertEq(
            principal.mulDiv(apy / 2, 100),
            simpleInterest.calcInterest(principal, dailyFrequency / 2),
            "wrong interest at day 180"
        );

        assertEq(
            principal.mulDiv(apy, 100),
            simpleInterest.calcInterest(principal, dailyFrequency),
            "wrong interest at day 360"
        );
    }

    // daily interest of 12% APY (uses 30 day count)
    // using the scaled up version for results that are fractional
    function test__SimpleInterestTest__InterestDailyScaled() public {
        uint256 apy = 10; // 10% APY
        uint256 dailyFrequency = Frequencies.toValue(Frequencies.Frequency.DAYS_360);
        SimpleInterest simpleInterest = new SimpleInterest(apy, dailyFrequency);

        uint256 principal = 540;
        uint256 SCALE = simpleInterest.SCALE();

        assertEq(0 * SCALE, simpleInterest.calcInterestScaleDecimals(principal, 0), "wrong interestScaled at day 0");

        // unscaledInterest = 540 * 0.10 * 1 / 360 = 54 / 360 = 0.15
        uint256 fifteenOver100 = SCALE.mulDiv(15, 100);
        assertEq(
            fifteenOver100, simpleInterest.calcInterestScaleDecimals(principal, 1), "wrong interestScaled at day 1"
        );
    }

    function test__SimpleInterestTest__DiscountingDaily() public {
        uint256 apy = 12; // APY in percentage

        uint256 dailyFrequency = Frequencies.toValue(Frequencies.Frequency.DAYS_365);
        SimpleInterest simpleInterest = new SimpleInterest(apy, dailyFrequency);

        uint256 principal = 400;
        assertEq(
            principal, simpleInterest.calcPrincipalFromDiscounted(principal, 0), "wrong principal from discounted at 0"
        );

        uint256 discountedFullTerm = principal - simpleInterest.calcInterest(principal, dailyFrequency);
        assertEq(
            principal,
            simpleInterest.calcPrincipalFromDiscounted(discountedFullTerm, dailyFrequency),
            "wrong principal from discounted at full term"
        );

        uint256 oneFifthTerm = dailyFrequency / 5; // 365 / 5 = 73 days
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
        uint256 dailyFrequency = Frequencies.toValue(Frequencies.Frequency.DAYS_365);
        SimpleInterest simpleInterest = new SimpleInterest(apy, dailyFrequency);

        uint256 principal = 400;
        uint256 SCALE = simpleInterest.SCALE();

        assertEq(
            principal * SCALE,
            simpleInterest.calcPrincipalFromDiscountedScaledScaleDecimals(principal * SCALE, 0),
            "wrong principalScaled from discounted at 0"
        );

        uint256 discountedFullTerm =
            principal * SCALE - simpleInterest.calcInterestScaleDecimals(principal, dailyFrequency);
        assertEq(
            principal * SCALE,
            simpleInterest.calcPrincipalFromDiscountedScaledScaleDecimals(discountedFullTerm, dailyFrequency),
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
