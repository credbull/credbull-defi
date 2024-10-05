// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ITimelockAsyncUnlock } from "@credbull/update_impl/ITimelockAsyncUnlock.sol";
import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title TimelockAsyncUnlock
 */
abstract contract TimelockAsyncUnlock is Initializable, ITimelockAsyncUnlock, ContextUpgradeable {
    struct UnlockRequest {
        uint256[] depositPeriods;
    }
    // uint256[] amounts;

    /**
     * Must necessary?
     * Yes, it must be; to implement maxRequestUnlock for depositPeriod
     */
    mapping(uint256 depositPeriod => mapping(address account => uint256 amount)) private _unlockRequests1;

    /**
     * Must necessary?
     * Yes, it can prevent 2 depth loop iteration
     */
    mapping(uint256 depositPeriod => mapping(address account => mapping(uint256 unlockPeriod => uint256 amount)))
        private _unlockRequestsByUnlockPeriod;

    /**
     * Must necessary?
     * Yes, it must be; need to get depositPeriods
     */
    mapping(uint256 unlockPeriod => mapping(address account => UnlockRequest)) private _unlockRequests2;

    uint256 private _noticePeriod;

    error TimelockAsyncUnlock__AuthorizeCallerFailed(address caller, address owner);
    error TimelockAsyncUnlock__InvalidArrayLength();
    error TimelockAsyncUnlock__ExceededMaxRequestUnlock(
        address owner, uint256 depositPeriod, uint256 amount, uint256 maxRequestUnlockAmount
    );
    error TimelockAsyncUnlock__UnlockBeforeDepositPeriod(
        address caller, address owner, uint256 depositPeriod, uint256 unlockPeriod
    );
    error TimelockAsyncUnlock__UnlockBeforeUnlockPeriod(
        address caller, address owner, uint256 currentPeriod, uint256 unlockPeriod
    );

    function noticePeriod() public view virtual returns (uint256) {
        return _noticePeriod;
    }

    function currentPeriod() public view virtual returns (uint256 currentPeriod_);

    function minUnlockPeriod() public view virtual returns (uint256) {
        return currentPeriod() + noticePeriod();
    }

    function lockedAmount(address owner, uint256 depositPeriod) public view virtual returns (uint256 lockedAmount_);

    function unlockRequested(address owner, uint256 depositPeriod) public view virtual returns (uint256) {
        return _unlockRequests1[depositPeriod][owner];
    }

    function maxRequestUnlock(address owner, uint256 depositPeriod) public view virtual returns (uint256) {
        return lockedAmount(owner, depositPeriod) - unlockRequested(owner, depositPeriod);
    }

    function requestUnlock(address owner, uint256[] memory depositPeriods, uint256[] memory amounts)
        public
        virtual
        returns (uint256)
    {
        if (depositPeriods.length != amounts.length) {
            revert TimelockAsyncUnlock__InvalidArrayLength();
        }

        _authorizeCaller(_msgSender(), owner);

        uint256 unlockPeriod = minUnlockPeriod();

        for (uint256 i = 0; i < depositPeriods.length;) {
            uint256 depositPeriod = depositPeriods[i];
            uint256 amount = amounts[i];
            if (amount > maxRequestUnlock(owner, depositPeriod)) {
                revert TimelockAsyncUnlock__ExceededMaxRequestUnlock(
                    owner, depositPeriod, amount, maxRequestUnlock(owner, depositPeriod)
                );
            }

            //
            _unlockRequests1[depositPeriod][owner] += amount;

            uint256 unlockRequestedAmount = _unlockRequestsByUnlockPeriod[depositPeriod][owner][unlockPeriod];

            //_unlockRequestsByUnlockPeriod[depositPeriod][owner][unlockPeriod] += amount;

            //
            if (unlockRequestedAmount == 0) {
                _unlockRequests2[unlockPeriod][owner].depositPeriods.push(depositPeriod);
                // _unlockRequests2[unlockPeriod][owner].amounts.push(amount);
            } else { // It means depositPeriod already exists
                    // No action
            }

            unlockRequestedAmount += amount;

            _unlockRequestsByUnlockPeriod[depositPeriod][owner][unlockPeriod] = unlockRequestedAmount;

            unchecked {
                ++i;
            }
        }

        return unlockPeriod;
    }

    function unlock(address owner, uint256 requestId) public virtual {
        uint256 unlockPeriod = requestId;

        uint256[] memory depositPeriods = _unlockRequests2[unlockPeriod][owner].depositPeriods;

        _performUnlockValidation(owner, depositPeriods, unlockPeriod);

        for (uint256 i = 0; i < depositPeriods.length;) {
            uint256 depositPeriod = depositPeriods[i];
            /*
            if (amount > unlockRequestedAmount) {
                revert TimelockAsyncUnlock__ExceededMaxUnlock(owner, amount, unlockRequestedAmount);
            } */
            uint256 unlockRequestedAmount = _unlockRequestsByUnlockPeriod[depositPeriod][owner][unlockPeriod];

            _unlockRequestsByUnlockPeriod[depositPeriod][owner][unlockPeriod] = 0;

            _unlockRequests1[depositPeriod][owner] -= unlockRequestedAmount;

            unchecked {
                ++i;
            }
        }

        delete _unlockRequests2[unlockPeriod][owner];
    }

    function _authorizeCaller(address caller, address owner) internal virtual {
        if (caller != owner) {
            revert TimelockAsyncUnlock__AuthorizeCallerFailed(caller, owner);
        }
    }

    function _performUnlockValidation(address owner, uint256[] memory depositPeriods, uint256 unlockPeriod)
        internal
        virtual
    {
        // Need to check with Ian
        if (unlockPeriod > currentPeriod()) {
            revert TimelockAsyncUnlock__UnlockBeforeUnlockPeriod(_msgSender(), owner, currentPeriod(), unlockPeriod);
        }

        // Need this code part?
        for (uint256 i = 0; i < depositPeriods.length;) {
            uint256 depositPeriod = depositPeriods[i];

            if (unlockPeriod < depositPeriod) {
                revert TimelockAsyncUnlock__UnlockBeforeDepositPeriod(_msgSender(), owner, depositPeriod, unlockPeriod);
            }

            unchecked {
                ++i;
            }
        }
    }
}
