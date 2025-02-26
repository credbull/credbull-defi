// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Timer } from "@credbull/timelock/Timer.sol";
import { Test } from "forge-std/Test.sol";

contract TimerTest is Test {
    uint256 public constant START_TIME = 1704110460000; // Jan 1, 2024 at 12:01pm UTC

    function test__Timer__InitialClockMode() public pure {
        assertEq(Timer.CLOCK_MODE(), "mode=timestamp");
    }

    function test__Timer__Consistency() public {
        uint256 initialTimestamp = Timer.timestamp();
        uint256 offsetSeconds = 1000;

        vm.warp(block.timestamp + offsetSeconds);

        assertEq(Timer.timestamp(), initialTimestamp + offsetSeconds);
        assertEq(Timer.timestamp(), block.timestamp);
        assertEq(Timer.clock(), uint48(block.timestamp));
    }

    function test__Timer__ElapsedTime() public {
        uint256 offsetSeconds = (48 hours) + 62;

        vm.warp(START_TIME + offsetSeconds); // warp to the offset

        assertEq(offsetSeconds, Timer.elapsedSeconds(START_TIME), "elapsedSeconds wrong");
        assertEq(offsetSeconds / (1 minutes), Timer.elapsedMinutes(START_TIME), "elapsedMinutes wrong");
        assertEq(offsetSeconds / (24 hours), Timer.elapsed24Hours(START_TIME), "elapsed24Hours wrong");
    }

    // vm.expectRevert() no longer works on internal functions by default.
    // below config enables it.  see: https://github.com/foundry-rs/foundry/pull/9537
    /// forge-config: default.allow_internal_expect_revert = true
    function test__Timer__ElapsedWithFutureStartTimereverts() public {
        uint256 futureStart = block.timestamp + 50 days;

        vm.expectRevert(abi.encodeWithSelector(Timer.Timer__StartTimeNotReached.selector, block.timestamp, futureStart));
        Timer.elapsedSeconds(futureStart); // "elapsed with future startTime should revert");
    }
}
