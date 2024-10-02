// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITimelockOpenEnded {
    function lock(address account, uint256 depositPeriod, uint256 amount) external;
}
