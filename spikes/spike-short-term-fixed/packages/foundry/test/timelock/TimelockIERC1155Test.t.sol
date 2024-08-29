// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { TimelockIERC1155 } from "@test/timelock/TimelockIERC1155.s.sol";
import { ITimelock } from "@test/interfaces/ITimelock.s.sol";
import { TimelockTest } from "@test/timelock/TimelockTest.t.sol";

contract TimelockIERC1155Test is TimelockTest {
    function setUp() public {
        timelock = new TimelockIERC1155(owner, lockReleasePeriod);
    }

    function toImpl(ITimelock _timelock) internal pure returns (TimelockIERC1155) {
        // Simulate time passing by setting the current time periods elapsed
        TimelockIERC1155 timelockImpl = TimelockIERC1155(address(_timelock));
        return timelockImpl;
    }

    function warpToPeriod(ITimelock _timelock, uint256 timePeriod) internal override {
        // Simulate time passing by setting the current time periods elapsed
        TimelockIERC1155 timelockImpl = toImpl(_timelock);
        timelockImpl.setCurrentPeriod(timePeriod);
    }
}
