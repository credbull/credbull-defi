// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { SimpleInterestYieldStrategy } from "@credbull/yield/strategy/SimpleInterestYieldStrategy.sol";

/**
 * @title SimpleInterestYieldStrategy
 * @dev Strategy where returns are calculated using SimpleInterest
 */
contract MinTenorYieldStrategy is SimpleInterestYieldStrategy {
    error MinTenorYieldStrategy_TenorNotReached(uint256 from, uint256 to, uint256 minTenor);

    uint256 public immutable MIN_TENOR;

    constructor(uint256 minTenor) {
        MIN_TENOR = minTenor;
    }

    /// @dev See {CalcSimpleInterest-calcInterest}
    function calcYield(address contextContract, uint256 principal, uint256 fromPeriod, uint256 toPeriod)
        public
        view
        virtual
        override
        returns (uint256 yield)
    {
        uint256 periodsBetween = toPeriod >= fromPeriod ? toPeriod - fromPeriod : 0;

        if (periodsBetween < MIN_TENOR) {
            revert MinTenorYieldStrategy_TenorNotReached(fromPeriod, toPeriod, MIN_TENOR);
        }

        return super.calcYield(contextContract, principal, fromPeriod, toPeriod);
    }
}
