// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IYieldStrategy } from "@credbull/yield/strategy/IYieldStrategy.sol";
import { TripleRateYieldStrategy } from "@credbull/yield/strategy/TripleRateYieldStrategy.sol";

import { Frequencies } from "@test/src/yield/Frequencies.t.sol";
import { TestTripleRateContext } from "@test/test/yield/context/TestTripleRateContext.t.sol";

import { Test } from "forge-std/Test.sol";

contract TripleRateYieldStrategyTest is Test {
    uint256 public constant TOLERANCE = 1; // with 6 decimals, diff of 0.000001
    uint256 public constant DECIMALS = 6;
    uint256 public constant SCALE = 10 ** DECIMALS;

    uint256 public constant PERCENT_5_SCALED = 5 * SCALE; // 5%
    uint256 public constant PERCENT_5_5_SCALED = 55 * SCALE / 10; // 5.5%
    uint256 public constant PERCENT_10_SCALED = 10 * SCALE; // 10%

    uint256 public constant DEFAULT_FULL_RATE = PERCENT_10_SCALED;
    uint256 public constant DEFAULT_REDUCED_RATE = PERCENT_5_SCALED;

    uint256 public constant EFFECTIVE_FROM_PERIOD = 0;
    uint256 public constant MATURITY_PERIOD = 30;

    uint256 public immutable DEFAULT_FREQUENCY = Frequencies.toValue(Frequencies.Frequency.DAYS_365);

    IYieldStrategy internal yieldStrategy;
    TestTripleRateContext internal context;
    address internal contextAddress;
    uint256 internal principal;

    function setUp() public {
        yieldStrategy = new TripleRateYieldStrategy();
        context = new TestTripleRateContext(
            DEFAULT_FULL_RATE,
            DEFAULT_REDUCED_RATE,
            EFFECTIVE_FROM_PERIOD,
            Frequencies.toValue(Frequencies.Frequency.DAYS_365),
            MATURITY_PERIOD,
            DECIMALS
        );
        contextAddress = address(context);
        principal = 1_000 * SCALE;
    }

    function test_TripleRateYieldStrategy_RevertCalcYield_WhenInvalidContextAddress() public {
        vm.expectRevert(IYieldStrategy.IYieldStrategy_InvalidContextAddress.selector);
        yieldStrategy.calcYield(address(0), principal, 1, MATURITY_PERIOD);
    }

    function test_TripleRateYieldStrategy_RevertCalcPrice_WhenInvalidContextAddress() public {
        vm.expectRevert(IYieldStrategy.IYieldStrategy_InvalidContextAddress.selector);
        yieldStrategy.calcPrice(address(0), 5);
    }

    function test_TripleRateYieldStrategy_RevertCalcYield_WhenInvalidPeriodRange() public {
        vm.expectRevert(abi.encodeWithSelector(IYieldStrategy.IYieldStrategy_InvalidPeriodRange.selector, 1, 1));
        yieldStrategy.calcYield(contextAddress, principal, 1, 1);

        vm.expectRevert(abi.encodeWithSelector(IYieldStrategy.IYieldStrategy_InvalidPeriodRange.selector, 5, 3));
        yieldStrategy.calcYield(contextAddress, principal, 5, 3);
    }

    function test_TripleRateYieldStrategy_CalcYield_AsExpected() public {
        // 21 Days:
        // $1,000 * ((5% / 365) * 21) = 2.876712
        assertApproxEqAbs(
            2_876_712,
            yieldStrategy.calcYield(contextAddress, principal, 1, 21),
            TOLERANCE,
            "incorrect 21 day reduced rate yield"
        );

        // 29 Days:
        // $1,000 * ((5% / 365) * 29) = 3.972603
        assertApproxEqAbs(
            3_972_603,
            yieldStrategy.calcYield(contextAddress, principal, 1, 29),
            TOLERANCE,
            "incorrect 29 day reduced rate yield"
        );

        // 30 Days:
        // $1,000 * ((10% / 365) * 30) = 8.219178
        assertApproxEqAbs(
            8_219_178,
            yieldStrategy.calcYield(contextAddress, principal, 1, 30),
            TOLERANCE,
            "incorrect 30 day full rate yield"
        );

        // 32 Days, no current tenor update:
        // ($1,000 * ((10% / 365) * 30) + ($1,000 * ((5% / 365) * 2))) = 8.493151
        assertApproxEqAbs(
            8_493_151,
            yieldStrategy.calcYield(contextAddress, principal, 1, 32),
            TOLERANCE,
            "incorrect 32 day combined rate yield"
        );

        // Update current tenor at Day 31:
        context.setReducedRate(PERCENT_5_5_SCALED, 31);

        // 37 Days:
        // ($1,000 * ((10% / 365) * 30) + ($1,000 * ((5.5% / 365) * 7))) = 9.273973
        assertApproxEqAbs(
            9_273_973,
            yieldStrategy.calcYield(contextAddress, principal, 1, 37),
            TOLERANCE,
            "incorrect 37 day combined rate yield"
        );

        // 22 Days, across Current Tenor Period:
        // ($1,000 * ((5% / 365) * 11) + ($1,000 * ((5.5% / 365) * 11))) = 3.164384
        assertApproxEqAbs(
            3_164_384,
            yieldStrategy.calcYield(contextAddress, principal, 20, 41),
            TOLERANCE,
            "incorrect 22 day across tenor periods rate yield"
        );
    }

    function test_TripleRateYieldStrategy_CalcPrice_AsExpected() public view {
        // 1 + ((10% / 365) * 0) = 1
        assertEq(1 * SCALE, yieldStrategy.calcPrice(contextAddress, 0), "price wrong at period 0");
        // 1 + ((10% / 365) * 1) ≈ 1.000273
        assertEq(1_000_273, yieldStrategy.calcPrice(contextAddress, 1), "price wrong at period 1");
        // 1 + ((10% / 365) * 30) = 1.008219
        assertEq(1_008_219, yieldStrategy.calcPrice(contextAddress, 30), "price wrong at period 30");
    }
}
