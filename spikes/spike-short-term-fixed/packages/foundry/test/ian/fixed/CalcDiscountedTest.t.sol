// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { CalcDiscounted } from "@credbull-spike/contracts/ian/fixed/CalcDiscounted.sol";
import { CalcSimpleInterest } from "@credbull-spike/contracts/ian/fixed/CalcSimpleInterest.sol";

import { Frequencies } from "@credbull-spike-test/ian/fixed/Frequencies.t.sol";

import { Test } from "forge-std/Test.sol";

contract CalcDiscountedTest is Test {
  using Math for uint256;

  uint256 public constant TOLERANCE = 5; // with 6 decimals, diff of 0.000005

  uint256 public constant scale = 10**6;

  function test__CalcDiscountedTest__Price() public {
    uint256 apy = 12; // APY in percentage
    uint256 frequency = Frequencies.toValue(Frequencies.Frequency.DAYS_360);

    uint256 calcInterestScale = CalcSimpleInterest.getScale();

    uint256 day0 = 0;
    assertEq(1 * calcInterestScale, CalcDiscounted.calcPriceWithScale(day0, apy, frequency)); // 1 + (0.12 * 0) / 360 = 1

    uint256 day1 = 1;
    assertEq(1_000_333_333_333_333_333, CalcDiscounted.calcPriceWithScale(day1, apy, frequency)); // 1 + (0.12 * 1) / 360 ≈ 1.00033

    uint256 day30 = 30;
    assertEq((101 * calcInterestScale / 100), CalcDiscounted.calcPriceWithScale(day30, apy, frequency)); // 1 + (0.12 * 30) / 360 = 1.01
  }

  function test__CalcDiscountedTest__Daily() public {
    uint256 apy = 12; // APY in percentage
    uint256 tenor = 30;
    uint256 frequency = Frequencies.toValue(Frequencies.Frequency.DAYS_360);

    uint256 principal = 200 * scale;

    uint256 actualDiscounted = CalcDiscounted.calcDiscounted(principal, tenor, apy, frequency);
    uint256 expectedDiscounted = principal.mulDiv(100, 101); // price at period 30 = 1.01
    assertApproxEqAbs(expectedDiscounted, actualDiscounted, TOLERANCE, string.concat("discount incorrect at period = ", vm.toString(tenor)));

    uint256 actualPrincipalFromDiscounted = CalcDiscounted.calcPrincipalFromDiscounted(actualDiscounted, tenor, apy, frequency);
    assertApproxEqAbs(principal, actualPrincipalFromDiscounted, TOLERANCE, string.concat("principalFromDiscounted incorrect at period = ", vm.toString(tenor)));

    uint256[5] memory numTimePeriodsElapsedArr = [0, 1, tenor - 1, tenor, tenor + 1];
    testDiscountingAtPeriods(200 * scale, numTimePeriodsElapsedArr, apy, frequency);
  }

  function test__CalcDiscountedTest__Monthly() public {
    uint256 apy = 12; // APY in percentage
    uint256 tenor = 24;
    uint256 frequency = Frequencies.toValue(Frequencies.Frequency.MONTHLY);

    uint256[5] memory numTimePeriodsElapsedArr = [0, 1, tenor - 1, tenor, tenor + 1];
    testDiscountingAtPeriods(200 * scale, numTimePeriodsElapsedArr, apy, frequency);
  }

  function testDiscountingAtPeriods(
    uint256 principal,
    uint256[5] memory numTimePeriodsElapsedArr,
    uint256 interestRatePercentage,
    uint256 frequency
  ) internal {

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
  ) internal {
    // The `calcPrincipalFromDiscounted` and `calcDiscounted` functions are designed to be mathematical inverses of each other.
    //  This means that applying `calcPrincipalFromDiscounted` to the output of `calcDiscounted` will return the original principal amount.

    uint256 discounted = CalcDiscounted.calcDiscounted(principal, numTimePeriodsElapsed, interestRatePercentage, frequency);
    uint256 principalFromDiscounted = CalcDiscounted.calcPrincipalFromDiscounted(discounted, numTimePeriodsElapsed, interestRatePercentage, frequency);

    assertApproxEqAbs(
      principal,
      principalFromDiscounted,
      TOLERANCE,
      string.concat("principalFromDiscount not inverse of principal at period = ", vm.toString(numTimePeriodsElapsed))
    );

    // verify for partial - does it hold that X% of principalFromDiscounted = X% principal
    uint256 discountedPartial = CalcDiscounted.calcDiscounted(principal.mulDiv(75, 100), numTimePeriodsElapsed, interestRatePercentage, frequency);
    uint256 principalFromDiscountedPartial =
                CalcDiscounted.calcPrincipalFromDiscounted(discountedPartial, numTimePeriodsElapsed, interestRatePercentage, frequency);

    assertApproxEqAbs(
      principal.mulDiv(75, 100),
      principalFromDiscountedPartial,
      TOLERANCE,
      string.concat("partical principalFromDiscount not inverse of principal at period = ", vm.toString(numTimePeriodsElapsed))
    );
  }
}
