// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IYieldStrategy } from "@credbull/yield/strategy/IYieldStrategy.sol";
import { TripleRateYieldStrategy } from "@credbull/yield/strategy/TripleRateYieldStrategy.sol";

import { Frequencies } from "@test/src/yield/Frequencies.t.sol";
import { TestTripleRateContext } from "@test/test/yield/context/TestTripleRateContext.t.sol";
import { YieldStrategyScenarioTest } from "@test/src/yield/strategy/YieldStrategyScenarioTest.t.sol";

contract TripleRateYieldStrategyScenarioTest is YieldStrategyScenarioTest {
    IYieldStrategy internal yieldStrategy;
    TestTripleRateContext internal context;

    function setUp() public override {
        yieldStrategy = new TripleRateYieldStrategy();
        context = new TestTripleRateContext(
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
        context.setReducedRateAt(_period, _reducedRate);
    }
}
