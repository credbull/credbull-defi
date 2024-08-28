// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { TimelockIERC1155 } from "./TimelockIERC1155.s.sol";
import { ITimelock } from "./ITimelock.s.sol";
import { Test } from "forge-std/Test.sol";
import { TimelockTest } from "./TimelockTest.t.sol";

contract TimelockIERC1155Test is TimelockTest {
    function setUp() public {
        timelock = new TimelockIERC1155(owner, lockReleasePeriod);
    }

    function warpToPeriod(ITimelock _timelock, uint256 timePeriod) internal override {
        // Simulate time passing by setting the current time periods elapsed
        TimelockIERC1155 timelockImpl = TimelockIERC1155(address(_timelock));
        timelockImpl.setCurrentTimePeriodsElapsed(timePeriod);
    }
}
