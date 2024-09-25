// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ITimelock } from "@credbull/timelock/ITimelock.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { ERC1155Supply } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TimelockIERC1155
 * @dev ERC1155-based token locking mechanism with defined lock and release periods.
 */
abstract contract TimelockIERC1155 is ITimelock, ERC1155, ERC1155Supply, Ownable {
    constructor(address initialOwner) ERC1155("") Ownable(initialOwner) { }

    /// @notice Returns the amount of tokens locked for `account` at `lockReleasePeriod`.
    function lockedAmount(address account, uint256 lockReleasePeriod)
        public
        view
        override
        returns (uint256 amountLocked)
    {
        return balanceOf(account, lockReleasePeriod);
    }

    /// @notice Locks `amount` of tokens for `account` until `lockReleasePeriod`.
    function lock(address account, uint256 lockReleasePeriod, uint256 amount) public override onlyOwner {
        _lockInternal(account, lockReleasePeriod, amount);
    }

    /// @dev Internal function to lock `amount` of tokens for `account` at `lockReleasePeriod`.
    function _lockInternal(address account, uint256 lockReleasePeriod, uint256 amount) internal {
        _mint(account, lockReleasePeriod, amount, "");
    }

    /// @notice Returns the amount of tokens unlockable for `account` at `lockReleasePeriod`.
    function maxUnlock(address account, uint256 lockReleasePeriod) public view override returns (uint256) {
        return currentPeriod() >= lockReleasePeriod ? lockedAmount(account, lockReleasePeriod) : 0;
    }

    /// @notice Unlocks `amount` of tokens for `account` at `lockReleasePeriod`.
    function unlock(address account, uint256 lockReleasePeriod, uint256 amount) public onlyOwner {
        _unlockInternal(account, lockReleasePeriod, amount);
    }

    /// @dev Internal function to unlock `amount` of tokens for `account` at `lockReleasePeriod`.
    function _unlockInternal(address account, uint256 lockReleasePeriod, uint256 amount) internal {
        uint256 currentPeriod_ = currentPeriod();
        if (currentPeriod_ < lockReleasePeriod) {
            revert ITimelock__LockDurationNotExpired(account, currentPeriod_, lockReleasePeriod);
        }

        uint256 maxUnlock_ = maxUnlock(account, lockReleasePeriod);
        if (maxUnlock_ < amount) {
            revert ITimelock_ExceededMaxUnlock(account, lockReleasePeriod, amount, maxUnlock_);
        }

        _burn(account, lockReleasePeriod, amount);
    }

    /// @notice Rolls over unlocked `amount` of tokens for `account` to a new lock period.
    function rolloverUnlocked(address account, uint256 lockReleasePeriod, uint256 amount) public virtual onlyOwner {
        uint256 maxUnlock_ = this.maxUnlock(account, lockReleasePeriod);

        if (amount > maxUnlock_) {
            revert ITimelock_ExceededMaxUnlock(account, lockReleasePeriod, amount, maxUnlock_);
        }

        _burn(account, lockReleasePeriod, amount);
        _mint(account, lockReleasePeriod + lockDuration(), amount, "");
    }

    /// @dev Internal hook to update balances after token transfers.
    function _update(address from, address to, uint256[] memory ids, uint256[] memory amount)
        internal
        override(ERC1155, ERC1155Supply)
    {
        ERC1155Supply._update(from, to, ids, amount);
    }

    /// @notice Returns the lock duration.
    function lockDuration() public view virtual returns (uint256 lockDuration_);

    /// @notice Returns the current period.
    function currentPeriod() public view virtual returns (uint256 currentPeriod_);

    /// @notice Returns the lock periods for `account` where the balance is non-zero.
    function lockPeriods(address account, uint256 fromPeriod, uint256 toPeriod)
        public
        view
        override
        returns (uint256[] memory lockPeriods_)
    {
        uint256 maxLockPeriods = (toPeriod - fromPeriod) + 1;
        uint256[] memory tempLockPeriods = new uint256[](maxLockPeriods);

        uint256 accountLockPeriodCount = 0;
        for (uint256 i = fromPeriod; i <= toPeriod; i++) {
            if (lockedAmount(account, i) > 0) {
                tempLockPeriods[accountLockPeriodCount] = i;
                accountLockPeriodCount++;
            }
        }

        uint256[] memory finalLockPeriods = new uint256[](accountLockPeriodCount);
        for (uint256 i = 0; i < accountLockPeriodCount; i++) {
            finalLockPeriods[i] = tempLockPeriods[i];
        }

        return finalLockPeriods;
    }
}
