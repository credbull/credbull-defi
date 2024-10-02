// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract TimelockAsyncUnlock {
    struct UnlockItem {
        address account;
        uint256 depositPeriod;
        uint256 unlockPeriod;
        uint256 amount;
    }

    // mapping(uint256 depositPeriod => mapping(address account => UnlockItem)) private _unlockRequests;

    mapping(uint256 depositPeriod => mapping(address account => uint256)) private _unlockRequests1;
    mapping(uint256 depositPeriod => mapping(address account => mapping(uint256 unlockPeriod => uint256))) private
        _unlockRequests2;

    uint256 private _noticePeriod;

    error TimelockAsyncUnlock__ExceededMaxUnlock();

    constructor(uint256 noticePeriod_) {
        _noticePeriod = noticePeriod_;
    }

    function noticePeriod() public view virtual returns (uint256) {
        return _noticePeriod;
    }

    /**
     * @dev Need implementation in child contract
     */
    function currentPeriod() public view virtual returns (uint256 currentPeriod_);

    function currentUnlockPeriod() public view virtual returns (uint256) {
        return currentPeriod() + noticePeriod();
    }

    /**
     * @dev Return locked token amount for depositPeriod in owner
     * In multi token vault, override lockedAmount to call sharesAtPeriod
     */
    function lockedAmount(address owner, uint256 depositPeriod) public view virtual returns (uint256 lockedAmount_);

    function unlockRequested(address owner, uint256 depositPeriod) public view virtual returns (uint256) {
        return _unlockRequests1[depositPeriod][owner];
    }

    function maxRequestUnlock(address owner, uint256 depositPeriod) public view virtual returns (uint256) {
        return lockedAmount(owner, depositPeriod) - unlockRequested(owner, depositPeriod);
    }
    /**
     * @dev Caller should be owner or approved user for owner
     */

    function requestUnlock(address owner, uint256 amount, uint256 depositPeriod) public virtual {
        /**
         * Need to check if msg.sender = owner or isApprovedForAll(owner, msg.sender) in multitoken vault
         */
        _unlockRequests1[depositPeriod][owner] += amount;
        _unlockRequests2[depositPeriod][owner][currentUnlockPeriod()] += amount;
    }

    /**
     * @dev every one can call this unlock function
     */
    function unlock(address owner, uint256 depositPeriod, uint256 unlockPeriod, uint256 amount) public virtual {
        uint256 unlockRequestedAmount = _unlockRequests2[depositPeriod][owner][unlockPeriod];

        if (amount > unlockRequestedAmount) {
            revert TimelockAsyncUnlock__ExceededMaxUnlock();
        }

        _unlockRequests2[depositPeriod][owner][unlockPeriod] = unlockRequestedAmount - amount;
        _unlockRequests1[depositPeriod][owner] -= amount;
    }
}
