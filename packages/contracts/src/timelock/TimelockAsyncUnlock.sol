// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ITimelockAsyncUnlock } from "@credbull/timelock/ITimelockAsyncUnlock.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";

abstract contract TimelockAsyncUnlock is ITimelockAsyncUnlock, Context {
    mapping(uint256 depositPeriod => mapping(address account => uint256 amount)) private _unlockRequests;
    mapping(uint256 depositPeriod => mapping(address account => mapping(uint256 unlockPeriod => uint256 amount)))
        private _unlockRequestsByUnlockPeriod;

    uint256 private _noticePeriod;

    error TimelockAsyncUnlock__ExceededMaxUnlock(address owner, uint256 amount, uint256 unlockRequestedAmount);
    error TimelockAsyncUnlock__UnlockBeforeDepositPeriod(
        address caller, address owner, uint256 depositPeriod, uint256 unlockPeriod
    );
    error TimelockAsyncUnlock__UnlockBeforeUnlockPeriod(
        address caller, address owner, uint256 currentPeriod, uint256 unlockPeriod
    );
    error TimelockAsyncUnlock__ExceededMaxRequestUnlock(address owner, uint256 amount, uint256 maxRequestUnlockAmount);
    error TimelockAsyncUnlock__AuthorizeCallerFailed(address caller, address owner);

    constructor(uint256 noticePeriod_) {
        _noticePeriod = noticePeriod_;
    }

    /**
     * @inheritdoc ITimelockAsyncUnlock
     */
    function noticePeriod() public view virtual returns (uint256) {
        return _noticePeriod;
    }

    /**
     * @inheritdoc ITimelockAsyncUnlock
     */
    function currentPeriod() public view virtual returns (uint256 currentPeriod_);

    function currentUnlockPeriod() public view virtual returns (uint256) {
        return currentPeriod() + noticePeriod();
    }

    /**
     * @inheritdoc ITimelockAsyncUnlock
     */
    function lockedAmount(address owner, uint256 depositPeriod) public view virtual returns (uint256 lockedAmount_);

    /**
     * @inheritdoc ITimelockAsyncUnlock
     */
    function unlockRequested(address owner, uint256 depositPeriod) public view virtual returns (uint256) {
        return _unlockRequests[depositPeriod][owner];
    }

    /**
     * @inheritdoc ITimelockAsyncUnlock
     */
    function unlockRequested(address owner, uint256 depositPeriod, uint256 unlockPeriod)
        public
        view
        virtual
        returns (uint256)
    {
        return _unlockRequestsByUnlockPeriod[depositPeriod][owner][unlockPeriod];
    }

    /**
     * @inheritdoc ITimelockAsyncUnlock
     */
    function maxRequestUnlock(address owner, uint256 depositPeriod) public view virtual returns (uint256) {
        return lockedAmount(owner, depositPeriod) - unlockRequested(owner, depositPeriod);
    }

    /**
     * @inheritdoc ITimelockAsyncUnlock
     */
    function requestUnlock(address owner, uint256 depositPeriod, uint256 amount)
        public
        virtual
        returns (uint256 unlockPeriod)
    {
        _authorizeCaller(_msgSender(), owner);

        if (maxRequestUnlock(owner, depositPeriod) < amount) {
            revert TimelockAsyncUnlock__ExceededMaxRequestUnlock(owner, amount, maxRequestUnlock(owner, depositPeriod));
        }

        unlockPeriod = currentUnlockPeriod();

        _unlockRequests[depositPeriod][owner] += amount;
        _unlockRequestsByUnlockPeriod[depositPeriod][owner][unlockPeriod] += amount;
    }

    /**
     * @inheritdoc ITimelockAsyncUnlock
     * @notice every one can call this unlock function
     */
    function unlock(address owner, uint256 depositPeriod, uint256 unlockPeriod, uint256 amount) public virtual {
        _performUnlockValidation(owner, depositPeriod, unlockPeriod);

        uint256 unlockRequestedAmount = _unlockRequestsByUnlockPeriod[depositPeriod][owner][unlockPeriod];

        if (amount > unlockRequestedAmount) {
            revert TimelockAsyncUnlock__ExceededMaxUnlock(owner, amount, unlockRequestedAmount);
        }

        _unlockRequestsByUnlockPeriod[depositPeriod][owner][unlockPeriod] = unlockRequestedAmount - amount;
        _unlockRequests[depositPeriod][owner] -= amount;
    }

    /**
     * @dev An internal function to check if the caller is eligible to manage the unlocks of the owner
     * It can be overridden and new authorization logic can be written in child contracts
     */
    function _authorizeCaller(address caller, address owner) internal virtual {
        if (caller != owner) {
            revert TimelockAsyncUnlock__AuthorizeCallerFailed(caller, owner);
        }
    }

    /**
     * @dev An internal function to check if unlock can be performed
     */
    function _performUnlockValidation(address owner, uint256 depositPeriod, uint256 unlockPeriod) internal virtual {
        if (unlockPeriod < depositPeriod) {
            revert TimelockAsyncUnlock__UnlockBeforeDepositPeriod(_msgSender(), owner, depositPeriod, unlockPeriod);
        }

        // Need to check with Ian
        if (unlockPeriod > currentPeriod()) {
            revert TimelockAsyncUnlock__UnlockBeforeUnlockPeriod(_msgSender(), owner, currentPeriod(), unlockPeriod);
        }
    }
}
