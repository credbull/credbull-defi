// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { CalcSimpleInterest } from "@credbull-spike/contracts/ian/fixed/CalcSimpleInterest.sol";
import { Frequencies } from "@credbull-spike-test/ian/fixed/Frequencies.t.sol";

import { Test } from "forge-std/Test.sol";

contract CalcInterestTest is Test {
  using Math for uint256;

  uint256 public constant TOLERANCE = 5; // with 6 decimals, diff of 0.000005

  uint256 public constant scale = 10**6;

  function test__CalcInterestTest__Daily() public {
    uint256 apy = 12; // APY in percentage
    uint256 tenor = 30;
    uint256 frequency = Frequencies.toValue(Frequencies.Frequency.DAYS_360);

    uint256 principal = 2000 * scale;

    // interest should be equal for these samples
    uint256 actualInterestDay0 = CalcSimpleInterest.calcInterest(principal, 0, apy, frequency);
    assertEq(0, actualInterestDay0, "interest should be 0 at day 0");

    uint256 actualInterestDay3 = CalcSimpleInterest.calcInterest(principal, 3, apy, frequency);
    assertEq(2 * scale, actualInterestDay3, "interest should be 2 at day 3");

    uint256 actualInterestDay30 = CalcSimpleInterest.calcInterest(principal, tenor, apy, frequency);
    assertEq(20 * scale, actualInterestDay30, "interest should be 20 at day 30");

    // interest should be almost equal for these samples
    uint256 actualInterestDay1 = CalcSimpleInterest.calcInterest(principal, 1, apy, frequency);
    assertEq(666_666, actualInterestDay1, "interest should be ~ 0.6666 at day 1");

    uint256 actualInterestDay2 = CalcSimpleInterest.calcInterest(principal, 2, apy, frequency);
    assertEq(1_333_333, actualInterestDay2, "interest should be ~ 1.3333 at day 2");

    uint256 actualInterestDay29 = CalcSimpleInterest.calcInterest(principal, 29, apy, frequency);
    assertEq(19_333_333, actualInterestDay29, "interest should be ~ 19.3333 at day 29");

    uint256 actualInterestDay721 = CalcSimpleInterest.calcInterest(principal, 721, apy, frequency);
    assertEq(480_666_666, actualInterestDay721, "interest should be ~ 480.6666 at day 721");
  }

}
