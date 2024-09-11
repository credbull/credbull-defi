// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ICalcInterest} from "@credbull-spike/contracts/ian/interfaces/ICalcInterest.sol";
import {ICalcDiscounted} from "@credbull-spike/contracts/ian/interfaces/ICalcDiscounted.sol";
import {ICalcInterestMetadata} from "@credbull-spike/contracts/ian/interfaces/ICalcInterestMetadata.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import {CalcInterestTest} from "@credbull-spike-test/ian/fixed/CalcInterestTest.t.sol";

import { Test } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";

abstract contract CalcDiscountedTest is CalcInterestTest {
  using Math for uint256;


  function testInterestAtPeriod(
    uint256 principal,
    ICalcInterestMetadata calcInterest,
    uint256 numTimePeriods
  ) internal override virtual {

    super.testInterestAtPeriod(principal, calcInterest, numTimePeriods);

    ICalcDiscounted calcDiscounted = ICalcDiscounted(address(calcInterest));

    // The `calcPrincipalFromDiscounted` and `calcDiscounted` functions are designed to be mathematical inverses of each other.
    //  This means that applying `calcPrincipalFromDiscounted` to the output of `calcDiscounted` will return the original principal amount.

    uint256 discounted = calcDiscounted.calcDiscounted(principal, numTimePeriods);
    uint256 principalFromDiscounted = calcDiscounted.calcPrincipalFromDiscounted(discounted, numTimePeriods);

    assertApproxEqAbs(
      principal,
      principalFromDiscounted,
      TOLERANCE,
      assertMsg("principalFromDiscount not inverse of principal", calcDiscounted, numTimePeriods)
    );

    // verify for partial - does it hold that X% of principalFromDiscounted = X% principal
    uint256 discountedPartial = calcDiscounted.calcDiscounted(principal.mulDiv(75, 100), numTimePeriods);
    uint256 principalFromDiscountedPartial =
      calcDiscounted.calcPrincipalFromDiscounted(discountedPartial, numTimePeriods);

    assertApproxEqAbs(
      principal.mulDiv(75, 100),
      principalFromDiscountedPartial,
      TOLERANCE,
      assertMsg("partial principalFromDiscount not inverse of principal", calcDiscounted, numTimePeriods)
    );
  }
}
