// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ITimelockAsyncUnlock } from "@credbull/timelock/ITimelockAsyncUnlock.sol";
import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title TimelockAsyncUnlock
 */
abstract contract TimelockAsyncUnlock is Initializable, ITimelockAsyncUnlock, ContextUpgradeable {
    struct UnlockRequest {
        uint256[] depositPeriods;
        uint256 amount;
    }

    mapping(uint256 depositPeriod => mapping(address account => uint256 amount)) private _unlockRequestByDepositPeriod;

    mapping(uint256 depositPeriod => mapping(address account => mapping(uint256 unlockPeriod => uint256 amount)))
        private _unlockRequestByUnlockPeriod;

    mapping(uint256 unlockPeriod => mapping(address account => UnlockRequest)) private _unlockRequests;

    uint256 private _noticePeriod;

    error TimelockAsyncUnlock__AuthorizeCallerFailed(address caller, address owner);
    error TimelockAsyncUnlock__InvalidArrayLength(uint256 depositPeriodsLength, uint256 amountsLength);
    error TimelockAsyncUnlock__ExceededMaxRequestUnlock(
        address owner, uint256 depositPeriod, uint256 amount, uint256 maxRequestUnlockAmount
    );
    error TimelockAsyncUnlock__UnlockBeforeDepositPeriod(
        address caller, address owner, uint256 depositPeriod, uint256 unlockPeriod
    );
    error TimelockAsyncUnlock__UnlockBeforeUnlockPeriod(
        address caller, address owner, uint256 currentPeriod, uint256 unlockPeriod
    );

    function __TimelockAsyncUnlock_init(uint256 noticePeriod_) internal virtual onlyInitializing {
        __Context_init();
        _noticePeriod = noticePeriod_;
    }

    function noticePeriod() public view virtual returns (uint256) {
        return _noticePeriod;
    }

    function currentPeriod() public view virtual returns (uint256 currentPeriod_);

    function minUnlockPeriod() public view virtual returns (uint256) {
        return currentPeriod() + noticePeriod();
    }

    function lockedAmount(address owner, uint256 depositPeriod) public view virtual returns (uint256 lockedAmount_);

    function unlockRequested(address owner, uint256 depositPeriod) public view virtual returns (uint256) {
        return _unlockRequestByDepositPeriod[depositPeriod][owner];
    }

    function unlockRequestedByRequestId(address owner, uint256 requestId) public view virtual returns (uint256) {
        uint256 unlockPeriod = requestId;

        return _unlockRequests[unlockPeriod][owner].amount;
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
            revert TimelockAsyncUnlock__InvalidArrayLength(depositPeriods.length, amounts.length);
        }

        _authorizeCaller(_msgSender(), owner);

        uint256 unlockPeriod = minUnlockPeriod();
        uint256 amountForUnlockPeriod = _unlockRequests[unlockPeriod][owner].amount;

        for (uint256 i = 0; i < depositPeriods.length;) {
            uint256 depositPeriod = depositPeriods[i];
            uint256 amount = amounts[i];
            if (amount > maxRequestUnlock(owner, depositPeriod)) {
                revert TimelockAsyncUnlock__ExceededMaxRequestUnlock(
                    owner, depositPeriod, amount, maxRequestUnlock(owner, depositPeriod)
                );
            }

            //
            _unlockRequestByDepositPeriod[depositPeriod][owner] += amount;

            uint256 unlockRequestedAmount = _unlockRequestByUnlockPeriod[depositPeriod][owner][unlockPeriod];

            if (unlockRequestedAmount == 0) {
                _unlockRequests[unlockPeriod][owner].depositPeriods.push(depositPeriod);
            }

            unlockRequestedAmount += amount;
            amountForUnlockPeriod += amount;

            _unlockRequestByUnlockPeriod[depositPeriod][owner][unlockPeriod] = unlockRequestedAmount;

            unchecked {
                ++i;
            }
        }

        _unlockRequests[unlockPeriod][owner].amount = amountForUnlockPeriod;

        return unlockPeriod;
    }

    function unlock(address owner, uint256 requestId)
        public
        virtual
        returns (uint256[] memory depositPeriods, uint256[] memory amounts)
    {
        // requestId is considered unlockPeriod in TimelockAsyncUnlock
        uint256 unlockPeriod = requestId;

        depositPeriods = _unlockRequests[unlockPeriod][owner].depositPeriods;

        _performUnlockValidation(owner, depositPeriods, unlockPeriod);

        amounts = new uint256[](depositPeriods.length);

        for (uint256 i = 0; i < depositPeriods.length;) {
            uint256 depositPeriod = depositPeriods[i];
            uint256 unlockRequestedAmount = _unlockRequestByUnlockPeriod[depositPeriod][owner][unlockPeriod];

            _unlockRequestByUnlockPeriod[depositPeriod][owner][unlockPeriod] = 0;
            _unlockRequestByDepositPeriod[depositPeriod][owner] -= unlockRequestedAmount;

            amounts[i] = unlockRequestedAmount;

            unchecked {
                ++i;
            }
        }

        delete _unlockRequests[unlockPeriod][owner];
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
        if (unlockPeriod > currentPeriod()) {
            revert TimelockAsyncUnlock__UnlockBeforeUnlockPeriod(_msgSender(), owner, currentPeriod(), unlockPeriod);
        }

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}
