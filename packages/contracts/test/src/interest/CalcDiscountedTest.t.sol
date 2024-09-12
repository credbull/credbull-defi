// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { CalcDiscounted } from "@credbull/interest/CalcDiscounted.sol";
import { Frequencies } from "@test/src/interest/Frequencies.t.sol";

import { Test } from "forge-std/Test.sol";

contract CalcDiscountedTest is Test {
    using Math for uint256;

    uint256 public constant TOLERANCE = 5; // with 6 decimals, diff of 0.000005

    uint256 public constant SCALE = 10 ** 6;

    function test__CalcDiscountedTest__Daily() public pure {
        uint256 apy = 12; // APY in percentage
        uint256 tenor = 30;
        uint256 frequency = Frequencies.toValue(Frequencies.Frequency.DAYS_360);

        uint256 principal = 200 * SCALE;

        uint256 price = CalcDiscounted.calcPriceFromInterest(tenor, apy, frequency, SCALE);

        uint256 actualDiscounted = CalcDiscounted.calcDiscounted(principal, price, SCALE);
        uint256 expectedDiscounted = principal.mulDiv(100, 101); // price at period 30 = 1.01
        assertApproxEqAbs(
            expectedDiscounted,
            actualDiscounted,
            TOLERANCE,
            string.concat("discount incorrect at period = ", vm.toString(tenor))
        );

        uint256 actualPrincipalFromDiscounted =
            CalcDiscounted.calcPrincipalFromDiscounted(actualDiscounted, price, SCALE);
        assertApproxEqAbs(
            principal,
            actualPrincipalFromDiscounted,
            TOLERANCE,
            string.concat("principalFromDiscounted incorrect at period = ", vm.toString(tenor))
        );

        uint256[5] memory numTimePeriodsElapsedArr = [0, 1, tenor - 1, tenor, tenor + 1];
        testDiscountingAtPeriods(200 * SCALE, numTimePeriodsElapsedArr, apy, frequency);
    }

    function test__CalcDiscountedTest__Monthly() public pure {
        uint256 apy = 12; // APY in percentage
        uint256 tenor = 24;
        uint256 frequency = Frequencies.toValue(Frequencies.Frequency.MONTHLY);

        uint256[5] memory numTimePeriodsElapsedArr = [0, 1, tenor - 1, tenor, tenor + 1];
        testDiscountingAtPeriods(200 * SCALE, numTimePeriodsElapsedArr, apy, frequency);
    }

    function testDiscountingAtPeriods(
        uint256 principal,
        uint256[5] memory numTimePeriodsElapsedArr,
        uint256 interestRatePercentage,
        uint256 frequency
    ) internal pure {
        // Iterate through the lock periods and calculate the principal for each
        for (uint256 i = 0; i < numTimePeriodsElapsedArr.length; i++) {
            uint256 numTimePeriodsElapsed = numTimePeriodsElapsedArr[i];

            testDiscountingAtPeriod(principal, numTimePeriodsElapsed, interestRatePercentage, frequency);
        }
    }

    function testDiscountingAtPeriod(
        uint256 principal,
        uint256 numTimePeriodsElapsed,
        uint256 interestRatePercentage,
        uint256 frequency
    ) internal pure {
        // The `calcPrincipalFromDiscounted` and `calcDiscounted` functions are designed to be mathematical inverses of each other.
        //  This means that applying `calcPrincipalFromDiscounted` to the output of `calcDiscounted` will return the original principal amount.

        uint256 price =
            CalcDiscounted.calcPriceFromInterest(numTimePeriodsElapsed, interestRatePercentage, frequency, SCALE);
        uint256 discounted = CalcDiscounted.calcDiscounted(principal, price, SCALE);
        uint256 principalFromDiscounted = CalcDiscounted.calcPrincipalFromDiscounted(discounted, price, SCALE);

        assertApproxEqAbs(
            principal,
            principalFromDiscounted,
            TOLERANCE,
            string.concat(
                "principalFromDiscount not inverse of principal at period = ", vm.toString(numTimePeriodsElapsed)
            )
        );

        // verify for partial - does it hold that X% of principalFromDiscounted = X% principal
        uint256 discountedPartial = CalcDiscounted.calcDiscounted(principal.mulDiv(75, 100), price, SCALE);
        uint256 principalFromDiscountedPartial =
            CalcDiscounted.calcPrincipalFromDiscounted(discountedPartial, price, SCALE);

        assertApproxEqAbs(
            principal.mulDiv(75, 100),
            principalFromDiscountedPartial,
            TOLERANCE,
            string.concat(
                "partical principalFromDiscount not inverse of principal at period = ",
                vm.toString(numTimePeriodsElapsed)
            )
        );
    }
}
