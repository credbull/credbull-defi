// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { AbstractYieldStrategy } from "@credbull/yield/strategy/AbstractYieldStrategy.sol";

import { Test } from "forge-std/Test.sol";

contract AbstractYieldStrategyTest is AbstractYieldStrategy, Test {
    uint256 public constant TOLERANCE = 1; // with 6 decimals, diff of 0.000001

    uint256 public constant DECIMALS = 6;
    uint256 public constant SCALE = 10 ** DECIMALS;

    function test_AbstractYieldStrategyTest_NoOfPeriodsCalculation(uint256 from_, uint256 to_) public pure {
        vm.assume(to_ > from_);
        vm.assume(to_ < type(uint256).max);

        assertEq(
            to_ - from_,
            _noOfPeriods(from_, to_),
            string.concat(
                "Incorrect No Of Periods: From: ",
                string.concat(vm.toString(from_), string.concat(", To: ", vm.toString(to_)))
            )
        );
    }

    /// @dev No impl stub.
    function calcYield(
        address, /* contextContract */
        uint256, /* principal */
        uint256, /* fromTimePeriod */
        uint256 /* toTimePeriod */
    ) public pure override returns (uint256 yield) {
        return 0;
    }

    /// @dev No impl stub.
    function calcPrice(address, /* contextContract */ uint256 /* numTimePeriodsElapsed */ )
        public
        pure
        override
        returns (uint256 price)
    {
        return 0;
    }
}
