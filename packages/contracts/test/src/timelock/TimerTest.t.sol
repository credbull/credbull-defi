// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Timer } from "@credbull/timelock/Timer.sol";
import { Test } from "forge-std/Test.sol";

contract TimerTest is Test {
    uint48 public constant START_TIME = 1704110460000; // Jan 1, 2024 at 12:01pm UTC

    Timer private clock;

    function setUp() public {
        clock = new Timer(1704110460000);
    }

    function test__Clock__InitialClockMode() public view {
        // verify that the clock mode is "mode=timestamp"
        assertEq(clock.CLOCK_MODE(), "mode=timestamp");
    }

    function test__Clock__Consistency() public {
        uint48 initialTimestamp = clock.clock();
        uint256 offsetSeconds = 1000;

        vm.warp(block.timestamp + offsetSeconds);

        uint48 newTimestamp = clock.clock();
        assertEq(newTimestamp, initialTimestamp + offsetSeconds);
        assertEq(newTimestamp, uint48(block.timestamp));
    }

    function test__Clock__ElapsedTime() public {
        uint256 offsetSeconds = (48 hours) + 62;

        vm.warp(START_TIME + offsetSeconds); // warp to the offset

        assertEq(offsetSeconds, clock.elapsedSeconds(), "elapsedSeconds wrong");
        assertEq(offsetSeconds / (1 minutes), clock.elapsedMinutes(), "elapsedMinutes wrong");
        assertEq(offsetSeconds / (24 hours), clock.elapsed24Hours(), "elapsed24Hours wrong");
    }
}
