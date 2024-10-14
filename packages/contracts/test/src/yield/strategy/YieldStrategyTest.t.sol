// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IYieldStrategy } from "@credbull/yield/strategy/IYieldStrategy.sol";
import { YieldStrategy } from "@credbull/yield/strategy/YieldStrategy.sol";

import { Test } from "forge-std/Test.sol";

import { console } from "forge-std/console.sol";

contract YieldStrategyTest is Test {
    uint256 public constant TOLERANCE = 1; // with 6 decimals, diff of 0.000001
    uint256 public constant DECIMALS = 6;
    uint256 public constant SCALE = 10 ** DECIMALS;

    function test_YieldStrategy_RangeInclusion_SetAsExpected(uint8 rangeInclusion) public {
        vm.assume(rangeInclusion <= uint8(type(IYieldStrategy.RangeInclusion).max));

        IYieldStrategy.RangeInclusion expected = IYieldStrategy.RangeInclusion(rangeInclusion);
        YieldStrategy underTest = new TestYieldStrategy(expected);
        assertTrue(expected == underTest.rangeInclusion(), "Unexpected Range Inclusion from accessor");
    }

    function test_YieldStrategy_RangeInclusionAll_PeriodRange_RevertWhen_From_GT_To(
        uint256 from,
        uint256 to,
        uint8 rangeInclusion
    ) public {
        vm.assume(from > to);
        vm.assume(rangeInclusion <= uint8(type(IYieldStrategy.RangeInclusion).max));

        YieldStrategy underTest = new TestYieldStrategy(IYieldStrategy.RangeInclusion(rangeInclusion));
        vm.expectRevert(
            abi.encodeWithSelector(
                IYieldStrategy.IYieldStrategy_InvalidPeriodRange.selector, from, to, underTest.rangeInclusion()
            )
        );
        underTest.periodRangeFor(from, to);
    }

    function test_YieldStrategy_RangeInclusion_NotNeither_PeriodRange_From_EQ_To(uint256 fromTo_, uint8 rangeInclusion_)
        public
    {
        // RangeInclusion.Neither is skipped, as it needs its own test.
        vm.assume(rangeInclusion_ < uint8(type(IYieldStrategy.RangeInclusion).max));

        IYieldStrategy.RangeInclusion rangeInclusion = IYieldStrategy.RangeInclusion(rangeInclusion_);
        YieldStrategy underTest = new TestYieldStrategy(rangeInclusion);

        string memory label = labelFor(rangeInclusion, fromTo_, fromTo_);
        (uint256 actualNoOfPeriods, uint256 actualFrom, uint256 actualTo) = underTest.periodRangeFor(fromTo_, fromTo_);
        assertEq(1, actualNoOfPeriods, string.concat("Incorrect No Of Periods: ", label));
        assertEq(fromTo_, actualFrom, string.concat("Incorrect Actual From: ", label));
        assertEq(fromTo_, actualTo, string.concat("Incorrect Actual To: ", label));
    }

    function test_YieldStrategy_RangeInclusionNeither_PeriodRange_RevertWhen_From_EQ_To(uint256 fromTo_) public {
        IYieldStrategy.RangeInclusion rangeInclusion = IYieldStrategy.RangeInclusion.Neither;
        YieldStrategy underTest = new TestYieldStrategy(rangeInclusion);

        vm.expectRevert(
            abi.encodeWithSelector(
                IYieldStrategy.IYieldStrategy_InvalidPeriodRange.selector, fromTo_, fromTo_, underTest.rangeInclusion()
            )
        );
        underTest.periodRangeFor(fromTo_, fromTo_);
    }

    function test_YieldStrategy_RangeInclusionNeither_PeriodRange_RevertWhen_From_Plus_1_EQ_To(uint256 from) public {
        vm.assume(from < UINT256_MAX);
        uint256 to = from + 1;

        IYieldStrategy.RangeInclusion rangeInclusion = IYieldStrategy.RangeInclusion.Neither;
        YieldStrategy underTest = new TestYieldStrategy(rangeInclusion);

        vm.expectRevert(
            abi.encodeWithSelector(
                IYieldStrategy.IYieldStrategy_InvalidPeriodRange.selector, from + 1, to, underTest.rangeInclusion()
            )
        );
        underTest.periodRangeFor(from, to);
    }

    function test_YieldStrategy_RangeInclusionBoth_PeriodRange_RevertWhen_From_0_To_Max() public {
        IYieldStrategy.RangeInclusion rangeInclusion = IYieldStrategy.RangeInclusion.Both;
        YieldStrategy underTest = new TestYieldStrategy(rangeInclusion);

        uint256 from = 0;
        uint256 to = UINT256_MAX;

        vm.expectRevert(
            abi.encodeWithSelector(
                IYieldStrategy.IYieldStrategy_InvalidPeriodRange.selector, from, to, underTest.rangeInclusion()
            )
        );
        underTest.periodRangeFor(from, to);
    }

    function test_YieldStrategy_RangeInclusionTo_PeriodRange_WorksConsistently(uint256 from, uint256 to) public {
        (string memory label, uint256 actualNoOfPeriods, uint256 actualFrom, uint256 actualTo) =
            periodRangeWorksConsistently(IYieldStrategy.RangeInclusion.To, from, to);
        assertEq(to - from, actualNoOfPeriods, string.concat("Incorrect No Of Periods: ", label));
        assertEq(from + 1, actualFrom, string.concat("Incorrect Actual From: ", label));
        assertEq(to, actualTo, string.concat("Incorrect Actual To: ", label));
    }

    function test_YieldStrategy_RangeInclusionFrom_PeriodRange_WorksConsistently(uint256 from, uint256 to) public {
        (string memory label, uint256 actualNoOfPeriods, uint256 actualFrom, uint256 actualTo) =
            periodRangeWorksConsistently(IYieldStrategy.RangeInclusion.From, from, to);
        assertEq(to - from, actualNoOfPeriods, string.concat("Incorrect No Of Periods: ", label));
        assertEq(from, actualFrom, string.concat("Incorrect Actual From: ", label));
        assertEq(to - 1, actualTo, string.concat("Incorrect Actual To: ", label));
    }

    function test_YieldStrategy_RangeInclusionBoth_PeriodRange_WorksConsistently(uint256 from, uint256 to) public {
        (string memory label, uint256 actualNoOfPeriods, uint256 actualFrom, uint256 actualTo) =
            periodRangeWorksConsistently(IYieldStrategy.RangeInclusion.Both, from, to);
        assertEq((to - from) + 1, actualNoOfPeriods, string.concat("Incorrect No Of Periods: ", label));
        assertEq(from, actualFrom, string.concat("Incorrect Actual From: ", label));
        assertEq(to, actualTo, string.concat("Incorrect Actual To: ", label));
    }

    function test_YieldStrategy_RangeInclusionNeither_PeriodRange_WorksConsistently(uint256 from, uint256 to) public {
        vm.assume(from < UINT256_MAX);
        vm.assume(from + 1 < to);

        (string memory label, uint256 actualNoOfPeriods, uint256 actualFrom, uint256 actualTo) =
            periodRangeWorksConsistently(IYieldStrategy.RangeInclusion.Neither, from, to);
        assertEq((to - from) - 1, actualNoOfPeriods, string.concat("Incorrect No Of Periods: ", label));
        assertEq(from + 1, actualFrom, string.concat("Incorrect Actual From: ", label));
        assertEq(to - 1, actualTo, string.concat("Incorrect Actual To: ", label));
    }

    function periodRangeWorksConsistently(IYieldStrategy.RangeInclusion rangeInclusion, uint256 from, uint256 to)
        private
        returns (string memory label, uint256 noOfPeriods, uint256 actualFromPeriod, uint256 actualToPeriod)
    {
        vm.assume(to > from);

        YieldStrategy underTest = new TestYieldStrategy(rangeInclusion);
        (uint256 actualNoOfPeriods, uint256 actualFrom, uint256 actualTo) = underTest.periodRangeFor(from, to);
        return (labelFor(rangeInclusion, from, to), actualNoOfPeriods, actualFrom, actualTo);
    }

    function labelFor(IYieldStrategy.RangeInclusion rangeInclusion, uint256 from, uint256 to)
        private
        pure
        returns (string memory)
    {
        string memory riLabel;
        if (rangeInclusion == IYieldStrategy.RangeInclusion.To) riLabel = "Range Inclusion: To, ";
        else if (rangeInclusion == IYieldStrategy.RangeInclusion.From) riLabel = "Range Inclusion: From, ";
        else if (rangeInclusion == IYieldStrategy.RangeInclusion.Both) riLabel = "Range Inclusion: Both, ";
        else if (rangeInclusion == IYieldStrategy.RangeInclusion.Neither) riLabel = "Range Inclusion: Neither, ";
        string memory fromLabel = string.concat("From: ", vm.toString(from));
        string memory toLabel = string.concat(", To: ", vm.toString(to));

        return string.concat(riLabel, string.concat(fromLabel, toLabel));
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
