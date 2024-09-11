// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ICalcInterest} from "@credbull-spike/contracts/ian/interfaces/ICalcInterest.sol";
import {ICalcInterestMetadata} from "@credbull-spike/contracts/ian/interfaces/ICalcInterestMetadata.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { Test } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";

abstract contract CalcInterestTest is Test {
  uint256 public constant TOLERANCE = 5; // with 6 decimals, diff of 0.000005

  using Math for uint256;

  function testInterestForTenor(uint256 principal, ICalcInterestMetadata calcInterest, uint256 tenorPeriod) internal {
    // due to small fractional numbers, principal needs to be SCALED to calculate correctly
    assertGe(principal, calcInterest.getScale(), "principal not in SCALE");

    // check at 0, 1, tenor-1, tenor, tenor+1

    testInterestAtPeriod(principal, calcInterest, 0);
    testInterestAtPeriod(principal, calcInterest, 1);

    testInterestAtPeriod(principal, calcInterest, tenorPeriod - 1);
    testInterestAtPeriod(principal, calcInterest, tenorPeriod);
    testInterestAtPeriod(principal, calcInterest, tenorPeriod + 1);

    testInterestAtPeriod(principal, calcInterest, 2 * tenorPeriod - 1);
    testInterestAtPeriod(principal, calcInterest, 2 * tenorPeriod);
    testInterestAtPeriod(principal, calcInterest, 2 * tenorPeriod + 1);
  }

  function testInterestAtPeriod(
    uint256 principal,
    ICalcInterestMetadata simpleInterest,
    uint256 numTimePeriods
  ) internal virtual {

    // TODO: duplcating the calculation - is there another way to check ?!?
    uint256 expectedInterest = (principal * simpleInterest.getInterestInPercentage() * numTimePeriods) / (simpleInterest.getFrequency() * 100);
    uint256 actualInterest = simpleInterest.calcInterest(principal, numTimePeriods);

    assertApproxEqAbs(
      expectedInterest,
      actualInterest,
      TOLERANCE,
      assertMsg("calcInterest not correct", simpleInterest, numTimePeriods)
    );
  }

  function assertMsg(
    string memory prefix,
    ICalcInterestMetadata calcInterest,
    uint256 numTimePeriods
  ) internal view returns (string memory) {
    return string.concat(prefix, toString(calcInterest), " timePeriod= ", vm.toString(numTimePeriods));
  }

  function toString(ICalcInterestMetadata calcInterest) internal view returns (string memory) {
    return string.concat(
      " ISimpleInterest [ ",
      " IR = ",
      vm.toString(calcInterest.getInterestInPercentage()),
      " Freq = ",
      vm.toString(calcInterest.getFrequency()),
      " ] "
    );
  }

}
