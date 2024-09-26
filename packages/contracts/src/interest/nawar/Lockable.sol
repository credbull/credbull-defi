// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Lockable {
    struct LockInfo {
        uint256 lockedUntil;
        uint256 shares;
        bool unlockRequested;
    }

    mapping(address => mapping(uint256 => LockInfo)) public locks;

    uint256 public noticePeriod;

    event SharesLocked(address indexed user, uint256 shares, uint256 depositPeriod, uint256 lockedUntil);
    event UnlockRequested(address indexed user, uint256 shares, uint256 depositPeriod, uint256 unlockTime);

    constructor(uint256 _noticePeriod) {
        noticePeriod = _noticePeriod;
    }

    modifier lockShares(address user, uint256 shares, uint256 depositPeriod) {
        locks[user][depositPeriod] =
            LockInfo({ shares: shares, lockedUntil: type(uint256).max, unlockRequested: false });
        emit SharesLocked(user, shares, depositPeriod, block.timestamp + noticePeriod);
        _;
    }

    modifier ensureSharesUnlocked(address user, uint256 depositPeriod) {
        LockInfo storage lockInfo = locks[user][depositPeriod];
        require(lockInfo.unlockRequested, "Unlock not requested yet");
        require(block.timestamp >= lockInfo.lockedUntil, "Shares are still locked");
        _;
    }

    modifier requestUnlock(address user, uint256 depositPeriod) {
        LockInfo storage lockInfo = locks[user][depositPeriod];
        require(lockInfo.shares > 0, "No shares to unlock for this period");
        require(!lockInfo.unlockRequested, "Unlock already requested");

        lockInfo.unlockRequested = true;
        lockInfo.lockedUntil = block.timestamp + noticePeriod;

        emit UnlockRequested(user, lockInfo.shares, depositPeriod, lockInfo.lockedUntil);
        _;
    }

    function isUnlocked(address user, uint256 depositPeriod) public view returns (bool) {
        LockInfo storage lockInfo = locks[user][depositPeriod];
        return lockInfo.unlockRequested && block.timestamp >= lockInfo.lockedUntil;
    }
}
