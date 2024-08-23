// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SimpleInterest } from "./SimpleInterest.s.sol";
import { Frequencies } from "./Frequencies.s.sol";

import { Test } from "forge-std/Test.sol";
import { ISimpleInterest } from "./ISimpleInterest.s.sol";

// exposes otherwise internal mechanisms for testing
contract SimpleInterestWithScale is SimpleInterest {
    constructor(uint256 interestRatePercentage, uint256 frequency) SimpleInterest(interestRatePercentage, frequency) { }

    // Override the internal function to change its visibility for testing
    function calcInterestWithScale(uint256 principal, uint256 numTimePeriodsElapsed) public view returns (uint256) {
        return super._calcInterestWithScale(principal, numTimePeriodsElapsed);
    }

    function calcPrincipalFromDiscountedWithScale(uint256 discounted, uint256 numTimePeriodsElapsed)
        public
        view
        returns (uint256)
    {
        return super._calcPrincipalFromDiscountedWithScale(discounted, numTimePeriodsElapsed);
    }
}

contract SimpleInterestTest is Test {
    uint256 public constant TOLERANCE = 500; // with 18 decimals, means allowed difference of 5E+16
    uint256 public constant NUM_CYCLES_TO_TEST = 2; // number of cycles in test (e.g. 2 years, 24 months, 720 days)

    using Math for uint256;

    function test__SimpleInterestTest__Monthly() public {
        uint256 apy = 12; // APY in percentage

        ISimpleInterest simpleInterest = new SimpleInterest(apy, Frequencies.toValue(Frequencies.Frequency.MONTHLY));

        simpleInterestTestHarness(200, simpleInterest);
    }

    //    function test__SimpleInterestTest__Daily360() public {
    //        uint256 apy = 12; // APY in percentage
    //
    //        ISimpleInterest simpleInterest =
    //                    new SimpleInterest(apy, Frequencies.toValue(Frequencies.Frequency.DAYS_360));
    //
    //        simpleInterestTestHarness(200, simpleInterest);
    //    }

    function simpleInterestTestHarness(uint256 principal, ISimpleInterest simpleInterest) public {
        uint256 maxNumPeriods = simpleInterest.getFrequency() * NUM_CYCLES_TO_TEST; // e.g. 2 years, 24 months, 720 days

        // check all periods for 24 months
        for (uint256 numTimePeriods = 0; numTimePeriods <= maxNumPeriods; numTimePeriods++) {
            // SimpleInterest has the nice property
            uint256 discountedFactor = simpleInterest.calcDiscounted(principal, numTimePeriods);
            uint256 principalFromDiscounted =
                simpleInterest.calcPrincipalFromDiscounted(discountedFactor, numTimePeriods);

            // The `calcPrincipalFromDiscounted` and `calcDiscounted` functions are designed to be mathematical inverses of each other.
            //  This means that applying `calcPrincipalFromDiscounted` to the output of `calcDiscounted` will return the original principal amount.

            //  discountedFactor = principal - interest, therefore interest = principal - discountedFactor
            assertEq(
                principal - discountedFactor,
                simpleInterest.calcInterest(principal, numTimePeriods),
                string.concat(
                    "calcInterest incorrect for ",
                    toString(simpleInterest),
                    ", numTimePeriods = ",
                    vm.toString(numTimePeriods)
                )
            );

            assertEq(
                principal,
                principalFromDiscounted,
                string.concat(
                    "calcDiscountFactor and calcPrincipalFromDiscount not inverses of each other ",
                    toString(simpleInterest),
                    ", numTimePeriods = ",
                    vm.toString(numTimePeriods)
                )
            );
        }
    }

    function toString(ISimpleInterest simpleInterest) public view returns (string memory) {
        return string.concat(
            " ISimpleInterest [ ",
            " IR = ",
            vm.toString(simpleInterest.getInterestInPercentage()),
            " Freq = ",
            vm.toString(simpleInterest.getFrequency()),
            " ] "
        );
    }
}
