// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import {CalcDiscounted} from "@credbull-spike/contracts/ian/fixed/CalcDiscounted.sol";
import { Frequencies } from "@credbull-spike-test/ian/fixed/Frequencies.t.sol";

import {ICalcDiscounted} from "@credbull-spike/contracts/ian/interfaces/ICalcDiscounted.sol";
import {CalcDiscountedTestBase} from "@credbull-spike-test/ian/fixed/CalcDiscountedTestBase.t.sol";

contract CalcDiscountedTest is CalcDiscountedTestBase {
  using Math for uint256;

  uint256 constant DECIMALS = 10; // number of decimals for scaling

  function test__SimpleInterestTest__CheckScale() public {
    uint256 apy = 10; // APY in percentage

    CalcDiscounted simpleInterest =
      new CalcDiscounted(apy, Frequencies.toValue(Frequencies.Frequency.DAYS_360), DECIMALS);

    uint256 scaleMinus1 = simpleInterest.getScale() - 1;

    // expect revert when principal not scaled
    vm.expectRevert();
    simpleInterest.calcInterest(scaleMinus1, 0);

    vm.expectRevert();
    simpleInterest.calcDiscounted(scaleMinus1, 0);
  }

  function test__SimpleInterestTest__Monthly() public {
    uint256 apy = 12; // APY in percentage

    CalcDiscounted simpleInterest =
      new CalcDiscounted(apy, Frequencies.toValue(Frequencies.Frequency.MONTHLY), DECIMALS);
    uint256 scale = simpleInterest.getScale();

    testInterestForTenor(200 * scale, simpleInterest, 12);
  }

  function test__SimpleInterestTest__Daily360() public {
    uint256 apy = 12; // APY in percentage

    CalcDiscounted simpleInterest =
      new CalcDiscounted(apy, Frequencies.toValue(Frequencies.Frequency.DAYS_360), DECIMALS);
    uint256 scale = simpleInterest.getScale();

    testInterestForTenor(200 * scale, simpleInterest, 30);
  }

  function test_SimpleInterestTest_Price() public {
    uint256 apy = 12; // APY in percentage

    CalcDiscounted simpleInterest =
      new CalcDiscounted(apy, Frequencies.toValue(Frequencies.Frequency.DAYS_360), DECIMALS);
    uint256 scale = simpleInterest.getScale();

    uint256 day0 = 0;
    assertEq(1 * scale, simpleInterest.calcPriceWithScale(day0)); // 1 + (0.12 * 0) / 360 = 1

    uint256 day1 = 1;
    assertEq((100_033_333_333 * scale / 100_000_000_000), simpleInterest.calcPriceWithScale(day1)); // 1 + (0.12 * 1) / 360 ≈ 1.00033

    uint256 day30 = 30;
    assertEq((101 * scale / 100), simpleInterest.calcPriceWithScale(day30)); // 1 + (0.12 * 30) / 360 = 1.01
  }

  function test_SimpleInterestTest_Rounding_Example() public {
    uint256 SCALE = 1e3; // Using a scale of 1000 (to represent 3 decimal places)

    uint256 principal = 1000 * SCALE;
    uint256 price = 1005 * SCALE;

    //    Discounted (Floor)  = floor(Principal / Price) =  floor(1000 / 1.005) = floor(995.02) = 995
    uint256 discountedFloor = principal.mulDiv(SCALE, price, Math.Rounding.Floor);
    assertEq(discountedFloor, 995, "Floor rounding failed");

    //    Discounted (Floor)  = ceil(Principal / Price) =  ceil(1000 / 1.005) = ceil(995.02) = 996
    uint256 discountedCeil = principal.mulDiv(SCALE, price, Math.Rounding.Ceil);
    assertEq(discountedCeil, 996, "Ceiling rounding failed");
  }
}
