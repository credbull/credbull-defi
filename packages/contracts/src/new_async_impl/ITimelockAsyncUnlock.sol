// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ITimelockAsyncUnlock
 */
interface ITimelockAsyncUnlock {
    function requestUnlock(address owner, uint256 amount, uint256 depositPeriod)
        external
        returns (uint256 unlockPeriod);

    function unlock(address owner, uint256 depositPeriod, uint256 unlockPeriod, uint256 amount) external;

    function noticePeriod() external view returns (uint256);
    function currentPeriod() external view returns (uint256);
    function currentUnlockPeriod() external view returns (uint256);

    function lockedAmount(address owner, uint256 depositPeriod) external view returns (uint256);

    function unlockRequested(address owner, uint256 depositPeriod) external view returns (uint256);

    function maxRequestUnlock(address owner, uint256 depositPeriod) external view returns (uint256);
}
