// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IInterest } from "@credbull-spike/contracts/ian/interfaces/IInterest.sol";
import { IDiscountedPrincipal } from "@credbull-spike/contracts/ian/interfaces/IDiscountedPrincipal.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { Test } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";

abstract contract InterestTest is Test {
  uint256 public constant TOLERANCE = 5; // with 6 decimals, diff of 0.000005
  uint256 public constant NUM_CYCLES_TO_TEST = 2; // number of cycles in test (e.g. 2 years, 24 months, 720 days)

  using Math for uint256;

  function testInterestToMaxPeriods(uint256 principal, IDiscountedPrincipal simpleInterest) internal {
    uint256 maxNumPeriods = simpleInterest.getFrequency() * NUM_CYCLES_TO_TEST; // e.g. 2 years, 24 months, 720 days

    // due to small fractional numbers, principal needs to be SCALED to calculate correctly
    assertGe(principal, simpleInterest.getScale(), "principal not in SCALE");

    // check all periods for 24 months
    for (uint256 numTimePeriods = 0; numTimePeriods <= maxNumPeriods; numTimePeriods++) {
      testInterestAtPeriod(principal, simpleInterest, numTimePeriods);
    }
  }

  function testInterestAtPeriod(
    uint256 principal,
    IDiscountedPrincipal simpleInterest,
    uint256 numTimePeriods
  ) internal virtual {
    // The `calcPrincipalFromDiscounted` and `calcDiscounted` functions are designed to be mathematical inverses of each other.
    //  This means that applying `calcPrincipalFromDiscounted` to the output of `calcDiscounted` will return the original principal amount.

    uint256 discounted = simpleInterest.calcDiscounted(principal, numTimePeriods);
    uint256 principalFromDiscounted = simpleInterest.calcPrincipalFromDiscounted(discounted, numTimePeriods);

    assertApproxEqAbs(
      principal,
      principalFromDiscounted,
      TOLERANCE,
      assertMsg("principalFromDiscount not inverse of principal", simpleInterest, numTimePeriods)
    );

    // verify for partial - does it hold that X% of principalFromDiscounted = X% principal
    uint256 discountedPartial = simpleInterest.calcDiscounted(principal.mulDiv(75, 100), numTimePeriods);
    uint256 principalFromDiscountedPartial =
      simpleInterest.calcPrincipalFromDiscounted(discountedPartial, numTimePeriods);

    assertApproxEqAbs(
      principal.mulDiv(75, 100),
      principalFromDiscountedPartial,
      TOLERANCE,
      assertMsg("partial principalFromDiscount not inverse of principal", simpleInterest, numTimePeriods)
    );
  }

  function assertMsg(
    string memory prefix,
    IDiscountedPrincipal simpleInterest,
    uint256 numTimePeriods
  ) internal view returns (string memory) {
    return string.concat(prefix, toString(simpleInterest), " timePeriod= ", vm.toString(numTimePeriods));
  }

  function toString(IDiscountedPrincipal simpleInterest) internal view returns (string memory) {
    return string.concat(
      " ISimpleInterest [ ",
      " IR = ",
      vm.toString(simpleInterest.getInterestInPercentage()),
      " Freq = ",
      vm.toString(simpleInterest.getFrequency()),
      " ] "
    );
  }

  function transferAndAssert(IERC20 _token, address fromAddress, address toAddress, uint256 amount) internal {
    uint256 beforeBalance = _token.balanceOf(toAddress);

    vm.startPrank(fromAddress);
    _token.transfer(toAddress, amount);
    vm.stopPrank();

    assertEq(beforeBalance + amount, _token.balanceOf(toAddress));
  }
}
