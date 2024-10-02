// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ITimelockAsyncUnlock
 */
interface ITimelockAsyncUnlock {
    /**
     * @dev Requests unlock amount for depositPeriod
     *
     * @param owner The address that owns tokens to be unlocked
     * @param depositPeriod the id of multi token
     * @param amount the amount of token to be requested for unlock
     *
     * @return unlockPeriod the time period when owner can unlock
     */
    function requestUnlock(address owner, uint256 depositPeriod, uint256 amount)
        external
        returns (uint256 unlockPeriod);

    /**
     * @dev Unlocks amount for depositPeriod and unlockPeriod
     *
     * @param owner The address that owns tokens to be unlocked
     * @param depositPeriod the id of multi token
     * @param unlockPeriod the time period when owner can unlock
     * @param amount the amount of token to be unlocked
     */
    function unlock(address owner, uint256 depositPeriod, uint256 unlockPeriod, uint256 amount) external;

    /**
     * @dev Return notice period
     */
    function noticePeriod() external view returns (uint256);

    /**
     * @dev Return current time period and it should be implemented in child implementation
     */
    function currentPeriod() external view returns (uint256);

    /**
     * @dev Return the unlock period based on current time
     */
    function currentUnlockPeriod() external view returns (uint256);

    /**
     * @dev Return the owner's locked token amount
     * It is same as owner's multi token balance at depositPeriod by default
     */
    function lockedAmount(address owner, uint256 depositPeriod) external view returns (uint256);

    /**
     * @dev Return the amount of owner that was already requested to be unlocked for depositPeriod
     */
    function unlockRequested(address owner, uint256 depositPeriod) external view returns (uint256);

    /**
     * @dev Return the amount of owner that can be requested to be unlocked for depositPeriod
     * This can be calculated simply by lockedAmount - unlockRequested
     */
    function maxRequestUnlock(address owner, uint256 depositPeriod) external view returns (uint256);
}
