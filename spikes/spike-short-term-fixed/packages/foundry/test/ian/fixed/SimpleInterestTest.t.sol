// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SimpleInterest } from "@credbull-spike/contracts/ian/fixed/SimpleInterest.sol";
import { Frequencies } from "@credbull-spike-test/ian/fixed/Frequencies.t.sol";

import { ISimpleInterest } from "@credbull-spike/contracts/ian/interfaces/ISimpleInterest.sol";
import { InterestTest } from "@credbull-spike-test/ian/fixed/InterestTest.t.sol";

contract SimpleInterestTest is InterestTest {
  using Math for uint256;

  uint256 constant DECIMALS = 10; // number of decimals for scaling

  function test__SimpleInterestTest__CheckScale() public {
    uint256 apy = 10; // APY in percentage

    ISimpleInterest simpleInterest = new SimpleInterest(apy, Frequencies.toValue(Frequencies.Frequency.DAYS_360), DECIMALS);

    uint256 scaleMinus1 = simpleInterest.getScale() - 1;

    // expect revert when principal not scaled
    vm.expectRevert();
    simpleInterest.calcInterest(scaleMinus1, 0);

    vm.expectRevert();
    simpleInterest.calcDiscounted(scaleMinus1, 0);
  }

  function test__SimpleInterestTest__Monthly() public {
    uint256 apy = 12; // APY in percentage

    ISimpleInterest simpleInterest = new SimpleInterest(apy, Frequencies.toValue(Frequencies.Frequency.MONTHLY), DECIMALS);
    uint256 scale = simpleInterest.getScale();

    testInterestToMaxPeriods(200 * scale, simpleInterest);
  }

  function test__SimpleInterestTest__Daily360() public {
    uint256 apy = 10; // APY in percentage

    ISimpleInterest simpleInterest = new SimpleInterest(apy, Frequencies.toValue(Frequencies.Frequency.DAYS_360), DECIMALS);
    uint256 scale = simpleInterest.getScale();

    testInterestToMaxPeriods(200 * scale, simpleInterest);
  }
}
