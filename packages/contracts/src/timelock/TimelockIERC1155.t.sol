// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ITimelock } from "@credbull/timelock/ITimelock.sol";

import { ERC1155SupplyUpgradeable } from
    "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title TimelockIERC1155
 * @dev ERC1155-based token locking mechanism with defined lock and release periods.
 * NB - keeps functions internal by NOT implementing ITimelock interface. children can implement ITimelock if desired.
 */
abstract contract TimelockIERC1155 is Initializable, ERC1155SupplyUpgradeable {
    constructor() {
        _disableInitializers();
    }

    function __TimelockIERC1155_init() internal onlyInitializing {
        __ERC1155Supply_init();
    }

    /// @notice Returns the amount of tokens locked for `account` at `lockReleasePeriod`.
    function lockedAmount(address account, uint256 lockReleasePeriod)
        public
        view
        virtual
        returns (uint256 lockedAmount_)
    {
        return balanceOf(account, lockReleasePeriod);
    }

    /// @dev Internal function to lock `amount` of tokens for `account` at `lockReleasePeriod`.
    function _lockInternal(address account, uint256 lockReleasePeriod, uint256 amount) internal {
        _mint(account, lockReleasePeriod, amount, "");
    }

    /// @notice Returns the max amount of tokens unlockable for `account` at `lockReleasePeriod`.
    function maxUnlock(address account, uint256 lockReleasePeriod)
        public
        view
        virtual
        returns (uint256 unlockableAmount_)
    {
        return currentPeriod() >= lockReleasePeriod ? lockedAmount(account, lockReleasePeriod) : 0;
    }

    /// @dev Internal function to unlock `amount` of tokens for `account` at `lockReleasePeriod`.
    function _unlockInternal(address account, uint256 lockReleasePeriod, uint256 amount) internal virtual {
        uint256 currentPeriod_ = currentPeriod();
        if (currentPeriod_ < lockReleasePeriod) {
            revert ITimelock.ITimelock__LockDurationNotExpired(account, currentPeriod_, lockReleasePeriod);
        }

        uint256 unlockableAmount_ = maxUnlock(account, lockReleasePeriod);
        if (unlockableAmount_ < amount) {
            revert ITimelock.ITimelock__ExceededMaxUnlock(account, lockReleasePeriod, amount, unlockableAmount_);
        }

        _burn(account, lockReleasePeriod, amount);
    }

    /// @notice Rolls over unlocked `amount` of tokens for `account` to a new lock period.
    function _rolloverUnlockedInternal(address account, uint256 origLockReleasePeriod, uint256 amount) internal {
        uint256 unlockableAmount_ = maxUnlock(account, origLockReleasePeriod);

        if (amount > unlockableAmount_) {
            revert ITimelock.ITimelock__ExceededMaxUnlock(account, origLockReleasePeriod, amount, unlockableAmount_);
        }

        _burn(account, origLockReleasePeriod, amount);
        _mint(account, origLockReleasePeriod + lockDuration(), amount, "");
    }

    /**
     * @inheritdoc ERC1155SupplyUpgradeable
     */
    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        virtual
        override(ERC1155SupplyUpgradeable)
    {
        ERC1155SupplyUpgradeable._update(from, to, ids, values);
    }

    function lockDuration() public view virtual returns (uint256 lockDuration_);

    function currentPeriod() public view virtual returns (uint256 currentPeriod_);

    /// @notice Returns the periods with locked tokens for `account` between `fromPeriod` and `toPeriod`.
    /// @dev Calls balanceOf twice to avoid creation of potentially large temp arrays.
    function lockPeriods(address account, uint256 fromPeriod, uint256 toPeriod, uint256 increment)
        public
        view
        virtual
        returns (uint256[] memory lockedPeriods_, uint256[] memory lockedAmounts_)
    {
        uint256 count = 0;
        for (uint256 i = fromPeriod; i <= toPeriod; i += increment) {
            if (balanceOf(account, i) > 0) {
                count++;
            }
        }

        lockedPeriods_ = new uint256[](count);
        lockedAmounts_ = new uint256[](count);

        uint256 index = 0;
        for (uint256 i = fromPeriod; i <= toPeriod; i += increment) {
            uint256 balance = balanceOf(account, i);
            if (balance > 0) {
                lockedPeriods_[index] = i;
                lockedAmounts_[index] = balance;
                index++;
            }
        }
    }
}
