// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ITimelockAsyncUnlock } from "@credbull/timelock/ITimelockAsyncUnlock.sol";
import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { EnumerableMap } from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

/**
 * @title TimelockAsyncUnlock
 */
abstract contract TimelockAsyncUnlock is Initializable, ITimelockAsyncUnlock, ContextUpgradeable {
    using EnumerableMap for EnumerableMap.UintToUintMap;

    uint256 private _noticePeriod;

    // maps account => requestId => map(depositPeriod, unlockAmount)
    mapping(address account => mapping(uint256 requestId => EnumerableMap.UintToUintMap)) private _unlockRequests;
    // maps account => map(depositPeriod, unlockAmount)
    mapping(address account => EnumerableMap.UintToUintMap) private _unlocksAtDepositPeriod;

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
    function unlockRequestedAmountForDepositPeriod(address owner, uint256 depositPeriod)
        public
        view
        virtual
        returns (uint256 amount)
    {
        return _unlocksAtDepositPeriod[owner].contains(depositPeriod)
            ? _unlocksAtDepositPeriod[owner].get(depositPeriod)
            : 0;
    }

    /**
     * @inheritdoc ITimelockAsyncUnlock
     */
    function unlockRequested(address owner, uint256 requestId)
        public
        view
        virtual
        returns (uint256[] memory depositPeriods, uint256[] memory amounts)
    {
        EnumerableMap.UintToUintMap storage depositPeriodsMap = _unlockRequests[owner][requestId];

        uint256 length = depositPeriodsMap.length();
        depositPeriods = new uint256[](length);
        amounts = new uint256[](length);

        for (uint256 i = 0; i < length; ++i) {
            (uint256 depositPeriod, uint256 amount) = depositPeriodsMap.at(i);
            depositPeriods[i] = depositPeriod;
            amounts[i] = amount;
        }

        return (depositPeriods, amounts);
    }

    /**
     * @inheritdoc ITimelockAsyncUnlock
     */
    function unlockRequestedAmount(address owner, uint256 requestId) public view virtual returns (uint256 amount_) {
        (, uint256[] memory amounts) = unlockRequested(owner, requestId);

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
    function unlockRequestedDepositPeriods(address owner, uint256 requestId)
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
        return lockedAmount(owner, depositPeriod) - unlockRequestedAmountForDepositPeriod(owner, depositPeriod);
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
        // requestId is considered unlockPeriod in TimelockAsyncUnlock
        uint256 unlockPeriod = requestId;

        EnumerableMap.UintToUintMap storage unlockRequestsByUnlockPeriod = _unlockRequests[owner][unlockPeriod];
        EnumerableMap.UintToUintMap storage unlockRequestsByOwner = _unlocksAtDepositPeriod[owner];

        uint256 length = unlockRequestsByUnlockPeriod.length();
        depositPeriods = new uint256[](length);
        amounts = new uint256[](length);

        // Get depositPeriods, amounts from storage using requestId
        for (uint256 i = 0; i < length; ++i) {
            (uint256 depositPeriod, uint256 amount) = unlockRequestsByUnlockPeriod.at(i);
            depositPeriods[i] = depositPeriod;
            amounts[i] = amount;
        }

        _handleUnlockValidation(owner, depositPeriods, unlockPeriod);

        // After processing, remove all entries from the EnumerableMap for this owner and unlockPeriod
        for (uint256 i = 0; i < length; ++i) {
            uint256 depositPeriod = depositPeriods[i];
            uint256 unlockAmount = amounts[i];

            unlockRequestsByUnlockPeriod.remove(depositPeriod);

            if (unlockRequestsByOwner.contains(depositPeriod)) {
                uint256 unlockAmountByOwner = unlockRequestsByOwner.get(depositPeriod);

                // If the unlocked amount equals the deposit amount, remove the entry
                if (unlockAmount >= unlockAmountByOwner) {
                    unlockRequestsByOwner.remove(depositPeriod);
                } else {
                    // Otherwise, reduce the deposit amount
                    unlockRequestsByOwner.set(depositPeriod, unlockAmountByOwner - unlockAmount);
                }
            }
        }
    }

    /**
     * @dev An internal function to reuqest unlock for single deposit period
     */
    function _handleSingleUnlockRequest(address owner, uint256 depositPeriod, uint256 unlockPeriod, uint256 amount)
        internal
        virtual
    {
        if (amount > maxRequestUnlock(owner, depositPeriod)) {
            revert TimelockAsyncUnlock__ExceededMaxRequestUnlock(
                owner, depositPeriod, amount, maxRequestUnlock(owner, depositPeriod)
            );
        }

        EnumerableMap.UintToUintMap storage unlockRequestsByUnlockPeriod = _unlockRequests[owner][unlockPeriod];
        EnumerableMap.UintToUintMap storage unlockRequestsByOwner = _unlocksAtDepositPeriod[owner];

        if (unlockRequestsByUnlockPeriod.contains(depositPeriod)) {
            uint256 unlockAmountByUnlockPeriod = unlockRequestsByUnlockPeriod.get(depositPeriod);
            uint256 unlockAmountByOwner = unlockRequestsByOwner.get(depositPeriod);

            unlockRequestsByUnlockPeriod.set(depositPeriod, unlockAmountByUnlockPeriod + amount);
            unlockRequestsByOwner.set(depositPeriod, unlockAmountByOwner + amount);
        } else {
            unlockRequestsByUnlockPeriod.set(depositPeriod, amount);
            unlockRequestsByOwner.set(depositPeriod, amount);
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
    function _handleUnlockValidation(address owner, uint256[] memory depositPeriods, uint256 unlockPeriod)
        internal
        virtual
    {
        if (unlockPeriod > currentPeriod()) {
            revert TimelockAsyncUnlock__UnlockBeforeUnlockPeriod(_msgSender(), owner, currentPeriod(), unlockPeriod);
        }

        for (uint256 i = 0; i < depositPeriods.length; ++i) {
            uint256 depositPeriod = depositPeriods[i];

            if (unlockPeriod < depositPeriod) {
                revert TimelockAsyncUnlock__UnlockBeforeDepositPeriod(_msgSender(), owner, depositPeriod, unlockPeriod);
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
