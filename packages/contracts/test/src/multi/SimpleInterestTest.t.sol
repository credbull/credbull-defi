// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SimpleInterest } from "./SimpleInterest.s.sol";
import { Frequencies } from "./Frequencies.s.sol";

import { Test } from "forge-std/Test.sol";
import { ISimpleInterest } from "./ISimpleInterest.s.sol";

import { console2 } from "forge-std/console2.sol";

contract SimpleInterestTest is Test {
    uint256 public constant TOLERANCE = 500; // with 18 decimals, means allowed difference of 5E+16
    uint256 public constant NUM_CYCLES_TO_TEST = 2; // number of cycles in test (e.g. 2 years, 24 months, 720 days)

    using Math for uint256;

    function test__SimpleInterestTest__Monthly() public {
        uint256 apy = 12; // APY in percentage

        ISimpleInterest simpleInterest = new SimpleInterest(apy, Frequencies.toValue(Frequencies.Frequency.MONTHLY));

        simpleInterestTestHarness(200, simpleInterest);
    }

    function test__SimpleInterestTest__Daily360() public {
        uint256 apy = 10; // APY in percentage

        ISimpleInterest simpleInterest = new SimpleInterest(apy, Frequencies.toValue(Frequencies.Frequency.DAYS_360));

        simpleInterestTestHarness(200, simpleInterest);
    }

    function simpleInterestTestHarness(uint256 principal, ISimpleInterest simpleInterest) public {
        uint256 maxNumPeriods = simpleInterest.getFrequency() * NUM_CYCLES_TO_TEST; // e.g. 2 years, 24 months, 720 days
        uint256 principalInWei = principal * simpleInterest.getScale();

        // check all periods for 24 months
        for (uint256 numTimePeriods = 0; numTimePeriods <= maxNumPeriods; numTimePeriods++) {
            // SimpleInterest has the nice property
            uint256 discountedWithScale = simpleInterest.calcDiscountedWithScale(principal, numTimePeriods); // TODO - why just principal ??

            console2.log("discountedWithScale", discountedWithScale);

            uint256 principalFromDiscountedWithScale =
                simpleInterest.calcPrincipalFromDiscountedWithScale(discountedWithScale, numTimePeriods);

            console2.log("principalFromDiscountedWithScale", discountedWithScale);

            // The `calcPrincipalFromDiscounted` and `calcDiscounted` functions are designed to be mathematical inverses of each other.
            //  This means that applying `calcPrincipalFromDiscounted` to the output of `calcDiscounted` will return the original principal amount.

            assertApproxEqAbs(
                principalInWei,
                principalFromDiscountedWithScale,
                TOLERANCE,
                assertMsg("principalFromDiscount not inverse of principal", simpleInterest, numTimePeriods)
            );

            //  discountedFactor = principal - interest, therefore interest = principal - discountedFactor
            assertEq(
                principalInWei - discountedWithScale,
                simpleInterest.calcInterestWithScale(principal, numTimePeriods),
                assertMsg("calcInterest incorrect for ", simpleInterest, numTimePeriods)
            );
        }
    }

    function assertMsg(string memory prefix, ISimpleInterest simpleInterest, uint256 numTimePeriods)
        public
        view
        returns (string memory)
    {
        return string.concat(prefix, toString(simpleInterest), " timePeriod= ", vm.toString(numTimePeriods));
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
