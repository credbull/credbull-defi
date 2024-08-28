// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { ISimpleInterest } from "./ISimpleInterest.s.sol";
import { IERC4626Interest } from "./IERC4626Interest.s.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { Test } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";

abstract contract InterestTest is Test {
    uint256 public constant TOLERANCE = 500; // with 18 decimals, means allowed difference of 5E+16
    uint256 public constant NUM_CYCLES_TO_TEST = 2; // number of cycles in test (e.g. 2 years, 24 months, 720 days)

    uint256 public constant SCALE = 1 * 10 ** 18; // number of cycles in test (e.g. 2 years, 24 months, 720 days)

    using Math for uint256;

    function testInterestToMaxPeriods(uint256 principal, ISimpleInterest simpleInterest) internal {
        uint256 maxNumPeriods = simpleInterest.getFrequency() * NUM_CYCLES_TO_TEST; // e.g. 2 years, 24 months, 720 days

        // due to small fractional numbers, principal needs to be SCALED to calculate correctly
        assertGe(principal, SCALE, "principal not in SCALE");

        // check all periods for 24 months
        for (uint256 numTimePeriods = 0; numTimePeriods <= maxNumPeriods; numTimePeriods++) {
            testInterestAtPeriod(principal, simpleInterest, numTimePeriods);
        }
    }

    function testInterestAtPeriod(uint256 principal, ISimpleInterest simpleInterest, uint256 numTimePeriods)
        internal
        virtual
    {
        console2.log("---------------------- simpleInterestTestHarness ----------------------");

        // The `calcPrincipalFromDiscounted` and `calcDiscounted` functions are designed to be mathematical inverses of each other.
        //  This means that applying `calcPrincipalFromDiscounted` to the output of `calcDiscounted` will return the original principal amount.

        uint256 discounted = simpleInterest.calcDiscounted(principal, numTimePeriods);
        uint256 principalFromDiscounted = simpleInterest.calcPrincipalFromDiscounted(discounted, numTimePeriods);

        assertApproxEqAbs(
            principal,
            principalFromDiscounted,
            TOLERANCE,
            assertMsg("principalFromDiscountW not inverse of principalInWei", simpleInterest, numTimePeriods)
        );

        //  discountedFactor = principal - interest, therefore interest = principal - discountedFactor
        assertApproxEqAbs(
            principal - discounted,
            simpleInterest.calcInterest(principal, numTimePeriods),
            10, // even smaller tolerance here
            assertMsg("calcInterest incorrect for ", simpleInterest, numTimePeriods)
        );
    }

    function testIERC4626InterestAtPeriod(uint256 principal, IERC4626Interest vault, uint256 numTimePeriods)
        internal
        virtual
    {
        uint256 expectedYield = principal + vault.calcInterest(principal, vault.getTenor());

        // check convertAtSharesAtPeriod and convertToAssetsAtPeriod

        // yieldAt(Periods+Tenor) = principalAtDeposit + interestForTenor - similar to how we test the interest.
        uint256 sharesInWeiAtPeriod = vault.convertToSharesAtPeriod(principal, numTimePeriods);
        uint256 assetsInWeiAtPeriod =
            vault.convertToAssetsAtPeriod(sharesInWeiAtPeriod, numTimePeriods + vault.getTenor());

        assertApproxEqAbs(
            expectedYield,
            assetsInWeiAtPeriod,
            TOLERANCE,
            assertMsg("yield does not equal principal + interest", vault, numTimePeriods)
        );

        // check convertAtShares and convertToAssets -- simulates the passage of time (e.g. block times)
        uint256 prevVaultTimePeriodsElapsed = vault.getCurrentTimePeriodsElapsed();

        vault.setCurrentTimePeriodsElapsed(numTimePeriods); // set deposit numTimePeriods
        uint256 sharesInWei = vault.convertToShares(principal); // now deposit

        vault.setCurrentTimePeriodsElapsed(numTimePeriods + vault.getTenor()); // set redeem numTimePeriods
        uint256 assetsInWei = vault.convertToAssets(sharesInWei); // now redeem

        assertApproxEqAbs(
            principal + vault.calcInterest(principal, vault.getTenor()),
            assetsInWei,
            TOLERANCE,
            assertMsg("yield does not equal principal + interest", vault, numTimePeriods)
        );

        vault.setCurrentTimePeriodsElapsed(prevVaultTimePeriodsElapsed); // restore the vault to previous state
    }

    function assertMsg(string memory prefix, ISimpleInterest simpleInterest, uint256 numTimePeriods)
        internal
        view
        returns (string memory)
    {
        return string.concat(prefix, toString(simpleInterest), " timePeriod= ", vm.toString(numTimePeriods));
    }

    function toString(ISimpleInterest simpleInterest) internal view returns (string memory) {
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
