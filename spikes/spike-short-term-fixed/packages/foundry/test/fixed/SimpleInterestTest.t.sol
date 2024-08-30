// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SimpleInterest } from "@credbull/contracts/fixed/SimpleInterest.sol";
import { Frequencies } from "@test/fixed/Frequencies.t.sol";

import { ISimpleInterest } from "@credbull/contracts/interfaces/ISimpleInterest.sol";
import { InterestTest } from "@test/fixed/InterestTest.t.sol";

contract SimpleInterestTest is InterestTest {
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

        testInterestToMaxPeriods(200 * SCALE, simpleInterest);
    }

    function test__SimpleInterestTest__Daily360() public {
        uint256 apy = 10; // APY in percentage

        ISimpleInterest simpleInterest = new SimpleInterest(apy, Frequencies.toValue(Frequencies.Frequency.DAYS_360));

        testInterestToMaxPeriods(200 * SCALE, simpleInterest);
    }
}
