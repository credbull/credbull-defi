// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ITimelockAsyncUnlock } from "@credbull/timelock/ITimelockAsyncUnlock.sol";
import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { EnumerableMap } from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

/**
 * @title TimelockAsyncUnlock
 *
 * @dev requestId = unlockPeriod and is unique by (accountAddress, requestId)
 */
abstract contract TimelockAsyncUnlock is Initializable, ITimelockAsyncUnlock, ContextUpgradeable {
    using EnumerableMap for EnumerableMap.UintToUintMap;

    uint256 private _noticePeriod;

    // user requested unlocks by requestId.  maps account => requestId => map(depositPeriod -> unlockAmount)
    mapping(address account => mapping(uint256 requestId => EnumerableMap.UintToUintMap)) private _unlockRequests;

    // cache of user requested unlocks by depositPeriod across ALL requests.  maps account => map(depositPeriod -> unlockAmount)
    mapping(address account => EnumerableMap.UintToUintMap) private _depositPeriodAmountCache;

    error TimelockAsyncUnlock__AuthorizeCallerFailed(address caller, address owner);
    error TimelockAsyncUnlock__InvalidArrayLength(uint256 depositPeriodsLength, uint256 amountsLength);
    error TimelockAsyncUnlock__ExceededMaxRequestUnlock(
        address owner, uint256 depositPeriod, uint256 amount, uint256 maxRequestUnlockAmount
    );
    error TimelockAsyncUnlock__ExceededMaxUnlock(
        address owner, uint256 depositPeriod, uint256 amount, uint256 maxUnlockAmount
    );
    error TimelockAsyncUnlock__UnlockBeforeDepositPeriod(
        address caller, address owner, uint256 depositPeriod, uint256 unlockPeriod
    );
    error TimelockAsyncUnlock__UnlockBeforeUnlockPeriod(
        address caller, address owner, uint256 currentPeriod, uint256 unlockPeriod
    );

    constructor() {
        _disableInitializers();
    }

    function __TimelockAsyncUnlock_init(uint256 noticePeriod_) internal virtual onlyInitializing {
        __Context_init();
        _noticePeriod = noticePeriod_;
    }

    /**
     * @inheritdoc ITimelockAsyncUnlock
     */
    function noticePeriod() public view virtual returns (uint256 noticePeriod_) {
        return _noticePeriod;
    }

    /**
     * @inheritdoc ITimelockAsyncUnlock
     */
    function currentPeriod() public view virtual returns (uint256 currentPeriod_);

    /**
     * @inheritdoc ITimelockAsyncUnlock
     */
    function minUnlockPeriod() public view virtual returns (uint256 minUnlockPeriod_) {
        return currentPeriod() + noticePeriod();
    }

    /**
     * @inheritdoc ITimelockAsyncUnlock
     */
    function lockedAmount(address owner, uint256 depositPeriod) public view virtual returns (uint256 lockedAmount_);

    /**
     * @inheritdoc ITimelockAsyncUnlock
     */
    function unlockRequestAmountByDepositPeriod(address owner, uint256 depositPeriod)
        public
        view
        virtual
        returns (uint256 amount)
    {
        return _depositPeriodAmountCache[owner].contains(depositPeriod)
            ? _depositPeriodAmountCache[owner].get(depositPeriod)
            : 0;
    }

    /**
     * @inheritdoc ITimelockAsyncUnlock
     */
    function unlockRequests(address owner, uint256 requestId)
        public
        view
        virtual
        returns (uint256[] memory depositPeriods, uint256[] memory amounts)
    {
        EnumerableMap.UintToUintMap storage unlockRequestsForRequestId = _unlockRequests[owner][requestId];

        uint256 length = unlockRequestsForRequestId.length();
        depositPeriods = new uint256[](length);
        amounts = new uint256[](length);

        for (uint256 i = 0; i < length; ++i) {
            (uint256 depositPeriod, uint256 amount) = unlockRequestsForRequestId.at(i);
            depositPeriods[i] = depositPeriod;
            amounts[i] = amount;
        }

        return (depositPeriods, amounts);
    }

    /**
     * @inheritdoc ITimelockAsyncUnlock
     */
    function unlockRequestAmount(address owner, uint256 requestId) public view virtual returns (uint256 amount_) {
        (, uint256[] memory amounts) = unlockRequests(owner, requestId);

        uint256 totalAmount = 0;

        for (uint256 i = 0; i < amounts.length; ++i) {
            totalAmount += amounts[i];
        }

        return totalAmount;
    }

    /**
     * @dev Return the an array containing all the depositPeriods
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function unlockRequestDepositPeriods(address owner, uint256 requestId)
        public
        view
        virtual
        returns (uint256[] memory depositPeriods_)
    {
        return _unlockRequests[owner][requestId].keys();
    }

    /**
     * @inheritdoc ITimelockAsyncUnlock
     */
    function maxRequestUnlock(address owner, uint256 depositPeriod) public view virtual returns (uint256) {
        return lockedAmount(owner, depositPeriod) - unlockRequestAmountByDepositPeriod(owner, depositPeriod);
    }

    /**
     * @inheritdoc ITimelockAsyncUnlock
     */
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

        for (uint256 i = 0; i < depositPeriods.length; ++i) {
            _handleSingleUnlockRequest(owner, depositPeriods[i], unlockPeriod, amounts[i]);
        }

        return unlockPeriod;
    }

    /**
     * @inheritdoc ITimelockAsyncUnlock
     * @notice every one can call this unlock function
     */
    function unlock(address owner, uint256 requestId)
        public
        virtual
        returns (uint256[] memory depositPeriods, uint256[] memory amounts)
    {
        // use copy of the depositPeriods and amounts.  we will be altering the storage in _unlock()
        (depositPeriods, amounts) = unlockRequests(owner, requestId);

        for (uint256 i = 0; i < depositPeriods.length; ++i) {
            _unlock(owner, depositPeriods[i], requestId, amounts[i]);
        }
    }

    /**
     * @dev Unlocks amount using requestId at the depositPeriod
     *
     * @param owner The address of the token owner who made the unlock request
     * @param depositPeriod The depositPeriod to unlock
     * @param requestId The ID of the unlock request generated by `requestUnlock`
     */
    function _unlock(address owner, uint256 depositPeriod, uint256 requestId, uint256 amountToUnlock) public virtual {
        _handleUnlockValidation(owner, depositPeriod, requestId);

        EnumerableMap.UintToUintMap storage unlockRequestsForRequestId = _unlockRequests[owner][requestId];

        uint256 maxUnlockableAmount =
            unlockRequestsForRequestId.contains(depositPeriod) ? unlockRequestsForRequestId.get(depositPeriod) : 0;
        if (amountToUnlock > maxUnlockableAmount) {
            revert TimelockAsyncUnlock__ExceededMaxUnlock(owner, depositPeriod, amountToUnlock, maxUnlockableAmount);
        }

        // reduce or remove the amount from the unlockRequests
        if (amountToUnlock == maxUnlockableAmount) {
            unlockRequestsForRequestId.remove(depositPeriod);
        } else {
            unlockRequestsForRequestId.set(depositPeriod, maxUnlockableAmount - amountToUnlock);
        }

        // reduce or remove the amount from the depositCache
        EnumerableMap.UintToUintMap storage depositPeriodAmountCache = _depositPeriodAmountCache[owner];

        if (depositPeriodAmountCache.contains(depositPeriod)) {
            uint256 totalAtDepositPeriod = depositPeriodAmountCache.get(depositPeriod);

            // If the unlocked amount equals the deposit amount, remove the entry
            if (amountToUnlock >= totalAtDepositPeriod) {
                depositPeriodAmountCache.remove(depositPeriod);
            } else {
                // Otherwise, reduce the deposit amount
                depositPeriodAmountCache.set(depositPeriod, totalAtDepositPeriod - amountToUnlock);
            }
        }
    }

    /**
     * @dev An internal function to request unlock for single deposit period
     */
    function _handleSingleUnlockRequest(address owner, uint256 depositPeriod, uint256 requestId, uint256 amount)
        internal
        virtual
    {
        if (amount > maxRequestUnlock(owner, depositPeriod)) {
            revert TimelockAsyncUnlock__ExceededMaxRequestUnlock(
                owner, depositPeriod, amount, maxRequestUnlock(owner, depositPeriod)
            );
        }

        EnumerableMap.UintToUintMap storage unlockRequestsForRequestId = _unlockRequests[owner][requestId];
        EnumerableMap.UintToUintMap storage depositPeriodAmountCache = _depositPeriodAmountCache[owner];

        if (unlockRequestsForRequestId.contains(depositPeriod)) {
            uint256 unlockAmountByUnlockPeriod = unlockRequestsForRequestId.get(depositPeriod);
            uint256 unlockAmountByOwner = depositPeriodAmountCache.get(depositPeriod);

            unlockRequestsForRequestId.set(depositPeriod, unlockAmountByUnlockPeriod + amount);
            depositPeriodAmountCache.set(depositPeriod, unlockAmountByOwner + amount);
        } else {
            unlockRequestsForRequestId.set(depositPeriod, amount);
            depositPeriodAmountCache.set(depositPeriod, amount);
        }
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
    function _handleUnlockValidation(address owner, uint256 depositPeriod, uint256 unlockPeriod) internal virtual {
        if (unlockPeriod > currentPeriod()) {
            revert TimelockAsyncUnlock__UnlockBeforeUnlockPeriod(_msgSender(), owner, currentPeriod(), unlockPeriod);
        }

        if (unlockPeriod < depositPeriod) {
            revert TimelockAsyncUnlock__UnlockBeforeDepositPeriod(_msgSender(), owner, depositPeriod, unlockPeriod);
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}
