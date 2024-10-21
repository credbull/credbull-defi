// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { CalcDiscounted } from "@credbull/yield/CalcDiscounted.sol";
import { Test } from "forge-std/Test.sol";

contract CalcDiscountedTest is Test {
    uint256 public constant TOLERANCE = 1; // with 6 decimals, diff of 0.000001

    uint256 public constant SCALE = 10 ** 6;

    function test__CalcDiscounted__ZeroOneTwo() public {
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
