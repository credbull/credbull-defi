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

    uint256 public constant SCALE = 1 ether; // number of cycles in test (e.g. 2 years, 24 months, 720 days)

    using Math for uint256;

    function test__SimpleInterestTest__CheckScale() public {
        uint256 apy = 10; // APY in percentage

        ISimpleInterest simpleInterest = new SimpleInterest(apy, Frequencies.toValue(Frequencies.Frequency.DAYS_360));

        uint256 scaleMinus1 = SCALE - 1;

        // expect revert when principal not scaled
        vm.expectRevert();
        simpleInterest.calcInterest(scaleMinus1, 0);

        vm.expectRevert();
        simpleInterest.calcDiscounted(scaleMinus1, 0);
    }

    function test__SimpleInterestTest__Monthly() public {
        uint256 apy = 12; // APY in percentage

        ISimpleInterest simpleInterest = new SimpleInterest(apy, Frequencies.toValue(Frequencies.Frequency.MONTHLY));

        simpleInterestTestHarness(200 * SCALE, simpleInterest);
    }

    function test__SimpleInterestTest__Daily360() public {
        uint256 apy = 10; // APY in percentage

        ISimpleInterest simpleInterest = new SimpleInterest(apy, Frequencies.toValue(Frequencies.Frequency.DAYS_360));

        simpleInterestTestHarness(200 * SCALE, simpleInterest);
    }

    function simpleInterestTestHarness(uint256 principal, ISimpleInterest simpleInterest) public {
        uint256 maxNumPeriods = simpleInterest.getFrequency() * NUM_CYCLES_TO_TEST; // e.g. 2 years, 24 months, 720 days

        // due to small fractional numbers, principal needs to be SCALED to calculate correctly
        assertGe(principal, SCALE, "principal not in SCALE");

        // check all periods for 24 months
        for (uint256 numTimePeriods = 0; numTimePeriods <= maxNumPeriods; numTimePeriods++) {
            // SimpleInterest has the nice property
            uint256 discounted = simpleInterest.calcDiscounted(principal, numTimePeriods);

            console2.log("discounted", discounted);

            uint256 principalFromDiscounted = simpleInterest.calcPrincipalFromDiscounted(discounted, numTimePeriods);

            console2.log("principalFromDiscounted", discounted);

            // The `calcPrincipalFromDiscounted` and `calcDiscounted` functions are designed to be mathematical inverses of each other.
            //  This means that applying `calcPrincipalFromDiscounted` to the output of `calcDiscounted` will return the original principal amount.

            assertApproxEqAbs(
                principal,
                principalFromDiscounted,
                TOLERANCE,
                assertMsg("principalFromDiscountW not inverse of principalInWei", simpleInterest, numTimePeriods)
            );

            //  discountedFactor = principal - interest, therefore interest = principal - discountedFactor
            assertEq(
                principal - discounted,
                simpleInterest.calcInterest(principal, numTimePeriods),
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
