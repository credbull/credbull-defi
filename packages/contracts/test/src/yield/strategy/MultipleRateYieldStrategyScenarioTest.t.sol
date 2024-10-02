// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IYieldStrategy } from "@credbull/yield/strategy/IYieldStrategy.sol";

import { MultipleRateYieldStrategy } from "@test/test/yield/strategy/MultipleRateYieldStrategy.t.sol";
import { MultipleRateContext } from "@test/test/yield/context/MultipleRateContext.t.sol";

import { YieldStrategyScenarioTest } from "@test/src/yield/strategy/YieldStrategyScenarioTest.t.sol";

import { Frequencies } from "@test/src/yield/Frequencies.t.sol";

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

    function _setReducedRate(uint256 reducedRateScaled_, uint256 effectiveFromPeriod_) internal virtual override {
        context.setReducedRate(effectiveFromPeriod_, reducedRateScaled_);
    }
}
