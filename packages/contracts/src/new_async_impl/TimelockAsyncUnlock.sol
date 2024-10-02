// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ITimelockAsyncUnlock } from "@credbull/new_async_impl/ITimelockAsyncUnlock.sol";

abstract contract TimelockAsyncUnlock is ITimelockAsyncUnlock {
    mapping(uint256 depositPeriod => mapping(address account => uint256 amount)) private _unlockRequests;
    mapping(uint256 depositPeriod => mapping(address account => mapping(uint256 unlockPeriod => uint256 amount)))
        private _unlockRequestsByUnlockPeriod;

    uint256 private _noticePeriod;

    error TimelockAsyncUnlock__ExceededMaxUnlock(address owner, uint256 amount, uint256 unlockRequestedAmount);

    modifier validateUnlockPeriod(uint256 depositPeriod, uint256 unlockPeriod) {
        if (unlockPeriod < depositPeriod) {
            revert();
        }

        // Need to check with Ian
        if (unlockPeriod >= currentPeriod()) {
            revert();
        }

        _;
    }

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
        return _unlockRequests[depositPeriod][owner];
    }

    function maxRequestUnlock(address owner, uint256 depositPeriod) public view virtual returns (uint256) {
        return lockedAmount(owner, depositPeriod) - unlockRequested(owner, depositPeriod);
    }
    /**
     * @dev Caller should be owner or approved user for owner
     */

    function requestUnlock(address owner, uint256 amount, uint256 depositPeriod)
        public
        virtual
        returns (uint256 unlockPeriod)
    {
        /**
         * Need to check if msg.sender = owner or isApprovedForAll(owner, msg.sender) in multitoken vault
         */
        if (maxRequestUnlock(owner, depositPeriod) < amount) {
            revert();
        }

        unlockPeriod = currentUnlockPeriod();

        _unlockRequests[depositPeriod][owner] += amount;
        _unlockRequestsByUnlockPeriod[depositPeriod][owner][unlockPeriod] += amount;
    }

    /**
     * @dev every one can call this unlock function
     */
    function unlock(address owner, uint256 depositPeriod, uint256 unlockPeriod, uint256 amount)
        public
        virtual
        validateUnlockPeriod(depositPeriod, unlockPeriod)
    {
        uint256 unlockRequestedAmount = _unlockRequestsByUnlockPeriod[depositPeriod][owner][unlockPeriod];

        if (amount > unlockRequestedAmount) {
            revert TimelockAsyncUnlock__ExceededMaxUnlock(owner, amount, unlockRequestedAmount);
        }

        _unlockRequestsByUnlockPeriod[depositPeriod][owner][unlockPeriod] = unlockRequestedAmount - amount;
        _unlockRequests[depositPeriod][owner] -= amount;
    }
}
