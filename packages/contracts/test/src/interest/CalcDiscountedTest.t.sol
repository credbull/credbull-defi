// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { CalcDiscounted } from "@credbull/interest/CalcDiscounted.sol";
import { Frequencies } from "@test/src/interest/Frequencies.t.sol";

import { Test } from "forge-std/Test.sol";

contract CalcDiscountedTest is Test {
    using Math for uint256;

    uint256 public constant TOLERANCE = 1; // with 6 decimals, diff of 0.000001

    uint256 public constant SCALE = 10 ** 6;

    function test__CalcDiscounted__Calc_Price() public pure {
        uint256 apy = 12; // APY in percentage
        uint256 frequency = Frequencies.toValue(Frequencies.Frequency.DAYS_360);

        assertEq(1 * SCALE, CalcDiscounted.calcPriceFromInterest(0, apy, frequency, SCALE)); // 1 + (0.12 * 0) / 360 = 1
        assertEq(1_000_333, CalcDiscounted.calcPriceFromInterest(1, apy, frequency, SCALE)); // 1 + (0.12 * 1) / 360 ≈ 1.00033
        assertEq((101 * SCALE / 100), CalcDiscounted.calcPriceFromInterest(30, apy, frequency, SCALE)); // 1 + (0.12 * 30) / 360 = 1.01
    }

    function test__CalcDiscounted__CheckPriceZeroOneTwo() public {
        uint256 principal = 1234 * SCALE;

        uint256 price0 = 0;
        vm.expectRevert(); // division by 0
        CalcDiscounted.calcDiscounted(principal, price0, SCALE);
        vm.expectRevert(); // division by 0
        CalcDiscounted.calcPrincipalFromDiscounted(principal, price0, SCALE);

        uint256 price1 = 1;
        assertEq(principal, CalcDiscounted.calcDiscounted(principal, price1, SCALE));
        assertEq(principal, CalcDiscounted.calcPrincipalFromDiscounted(principal, price1, SCALE));

        uint256 price2 = 2;
        uint256 halfPrincipal = principal / 2;
        assertEq(halfPrincipal, CalcDiscounted.calcDiscounted(principal, price2, SCALE));
        assertEq(principal, CalcDiscounted.calcPrincipalFromDiscounted(halfPrincipal, price2, SCALE));
    }

    function test__CalcDiscounted__PrincipalShouldBeInverseOfDiscounted() public pure {
        uint256 principal = 9876 * SCALE;

        uint256 price = 101 * SCALE / 100; // 1.01

        uint256 discounted = CalcDiscounted.calcDiscounted(principal, price, SCALE);
        uint256 principalFromDiscounted = CalcDiscounted.calcPrincipalFromDiscounted(discounted, price, SCALE);

        assertApproxEqAbs(
            principal,
            principalFromDiscounted,
            1,
            string.concat("principalFromDiscount not inverse at price = ", vm.toString(price))
        );
    }
}
