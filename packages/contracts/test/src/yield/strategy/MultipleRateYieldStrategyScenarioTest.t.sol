// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IYieldStrategy } from "@credbull/yield/strategy/IYieldStrategy.sol";

import { MultipleRateYieldStrategy } from "@test/test/yield/strategy/MultipleRateYieldStrategy.t.sol";
import { MultipleRateContext } from "@test/test/yield/context/MultipleRateContext.t.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { YieldStrategyScenarioTest } from "@test/src/yield/strategy/YieldStrategyScenarioTest.t.sol";

import { Frequencies } from "@test/src/yield/Frequencies.t.sol";

contract MultipleRateYieldStrategyScenarioTest is YieldStrategyScenarioTest {
    IYieldStrategy internal yieldStrategy;
    MultipleRateContext internal context;

    function setUp() public override {
        yieldStrategy = new MultipleRateYieldStrategy();
        context = _createMultiRateContext(
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

    function _createMultiRateContext(
        uint256 fullRate,
        uint256 reducedRate,
        uint256 frequency,
        uint256 tenor,
        uint256 decimals
    ) private returns (MultipleRateContext) {
        MultipleRateContext _context = new MultipleRateContext();
        context = MultipleRateContext(
            address(
                new ERC1967Proxy(
                    address(_context),
                    abi.encodeWithSelector(
                        _context.initialize.selector, fullRate, reducedRate, frequency, tenor, decimals
                    )
                )
            )
        );
        return _context;
    }
}
