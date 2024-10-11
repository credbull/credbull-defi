// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IYieldStrategy } from "@credbull/yield/strategy/IYieldStrategy.sol";
import { YieldStrategy } from "@credbull/yield/strategy/YieldStrategy.sol";

import { Test } from "forge-std/Test.sol";

contract YieldStrategyTest is Test {
    uint256 public constant TOLERANCE = 1; // with 6 decimals, diff of 0.000001

    uint256 public constant DECIMALS = 6;
    uint256 public constant SCALE = 10 ** DECIMALS;

    function test_YieldStrategy_PeriodRange_InclusionAll_RevertWhen_FromGTTo(
        uint256 from,
        uint256 to,
        uint8 rangeInclusion
    ) public {
        vm.assume(from > to);
        vm.assume(to < type(uint256).max);
        vm.assume(rangeInclusion <= uint8(type(IYieldStrategy.RangeInclusion).max));

        YieldStrategy underTest = new TestYieldStrategy(IYieldStrategy.RangeInclusion(rangeInclusion));
        vm.expectRevert(
            abi.encodeWithSelector(
                IYieldStrategy.IYieldStrategy_InvalidPeriodRange.selector, from, to, underTest.rangeInclusion()
            )
        );
        underTest.periodRangeFor(from, to);
    }

    function test_YieldStrategy_PeriodRange_InclusionTo(uint256 from, uint256 to) public {
        vm.assume(to > from);
        vm.assume(to < type(uint256).max);

        YieldStrategy underTest = new TestYieldStrategy(IYieldStrategy.RangeInclusion.To);

        string memory label = labelFor(from, to);
        (uint256 actualNoOfPeriods, uint256 actualFrom, uint256 actualTo) = underTest.periodRangeFor(from, to);
        assertEq(to - from, actualNoOfPeriods, string.concat("Incorrect No Of Periods: ", label));
        assertEq(from + 1, actualFrom, string.concat("Incorrect Actual From: ", label));
        assertEq(to, actualTo, string.concat("Incorrect Actual To: ", label));
    }

    function test_YieldStrategy_PeriodRange_InclusionTo_FromEqualTo(uint256 fromTo_) public {
        vm.assume(fromTo_ < type(uint256).max);

        YieldStrategy underTest = new TestYieldStrategy(IYieldStrategy.RangeInclusion.To);

        string memory label = labelFor(fromTo_, fromTo_);
        (uint256 actualNoOfPeriods, uint256 actualFrom, uint256 actualTo) = underTest.periodRangeFor(fromTo_, fromTo_);
        assertEq(1, actualNoOfPeriods, string.concat("Incorrect No Of Periods: ", label));
        assertEq(fromTo_, actualFrom, string.concat("Incorrect Actual From: ", label));
        assertEq(fromTo_, actualTo, string.concat("Incorrect Actual To: ", label));
    }

    function labelFor(uint256 from, uint256 to) private pure returns (string memory) {
        return string.concat(string.concat("From: ", vm.toString(from)), string.concat(", To: ", vm.toString(to)));
    }
}

contract TestYieldStrategy is YieldStrategy {
    constructor(RangeInclusion rangeInclusion_) YieldStrategy(rangeInclusion_) { }

    /// @dev No impl stub.
    function calcYield(address, uint256, uint256, uint256) public pure override returns (uint256 yield) {
        return 0;
    }

    /// @dev No impl stub.
    function calcPrice(address, uint256) public pure override returns (uint256 price) {
        return 0;
    }
}
