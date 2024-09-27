// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IYieldStrategy } from "@credbull/strategy/IYieldStrategy.sol";

import { MultipleRateYieldStrategy } from "@test/test/strategy/MultipleRateYieldStrategy.t.sol";
import { MultipleRateContext } from "@test/test/interest/context/MultipleRateContext.t.sol";

import { YieldStrategyScenarioTest } from "@test/src/strategy/YieldStrategyScenarioTest.t.sol";

import { Frequencies } from "@test/src/interest/Frequencies.t.sol";

import { Test } from "forge-std/Test.sol";

contract MultipleRateYieldStrategyScenarioTest is YieldStrategyScenarioTest {
    IYieldStrategy internal yieldStrategy;
    MultipleRateContext internal context;

    function setUp() public override {
        yieldStrategy = new MultipleRateYieldStrategy();
        context = new MultipleRateContext(
            DEFAULT_FULL_RATE,
            DEFAULT_REDUCED_RATE,
            Frequencies.toValue(Frequencies.Frequency.DAYS_365),
            MATURITY_PERIOD,
            DECIMALS
        );
        super.setUp();
    }

    function _yieldStrategy() internal virtual override returns (IYieldStrategy) {
        return yieldStrategy;
    }

    function _contextAddress() internal virtual override returns (address) {
        return address(context);
    }

    function _setReducedRateAt(uint256 _period, uint256 _reducedRate) internal virtual override {
        context.setReducedRate(_period, _reducedRate);
    }
}
