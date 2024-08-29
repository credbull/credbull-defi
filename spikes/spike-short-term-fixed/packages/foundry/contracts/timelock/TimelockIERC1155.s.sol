// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.23;

import { ITimelock } from "@credbull/contracts/interfaces/ITimelock.s.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { ERC1155Supply } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TimelockIERC1155
 * @dev A contract that implements token locking functionality using the ERC1155 standard.
 *      This contract allows tokens to be locked for a specific period and prevents their transfer until the lock period has expired.
 *      At maturity, users can unlock their tokens or choose to roll them over into a new lock period.
 *      The contract is owned, meaning only the owner can perform certain actions like locking, unlocking, and rolling over investments.
 *
 * @notice The TimelockIERC1155 contract is part of the Credbull investment product, providing a mechanism to lock investments until maturity.
 *         It is designed to prevent early withdrawal, ensuring that investments remain locked for the entire tenor of the product.
 *
 * @dev This contract inherits from the OpenZeppelin ERC1155, ERC1155Supply, and Ownable contracts.
 *      The main functionality includes locking, unlocking, and rolling over investments.
 *
 */
contract TimelockIERC1155 is ITimelock, ERC1155, ERC1155Supply, Ownable {
    uint256 public lockDuration;
    uint256 public currentPeriod = 0;

    /**
     * @dev Constructor to initialize the Timelock contract with an owner and lock duration.
     * @param _initialOwner The address of the contract owner.
     * @param _lockDuration The duration of the lock period.
     */
    constructor(address _initialOwner, uint256 _lockDuration) ERC1155("credbull.io/funds/1") Ownable(_initialOwner) {
        lockDuration = _lockDuration;
    }

    /**
     * @notice Returns the amount of tokens currently locked for a specific account and release period.
     * @param account The address of the account whose tokens are locked.
     * @param lockReleasePeriod The period during which these tokens will be released.
     * @return amountLocked The amount of tokens locked for the given account and release period.
     */
    function getLockedAmount(address account, uint256 lockReleasePeriod) public view returns (uint256 amountLocked) {
        return balanceOf(account, lockReleasePeriod);
    }

    /**
     * @notice Locks a specified amount of tokens for a particular account until a given release period.
     * @param account The address of the account whose tokens are to be locked.
     * @param lockReleasePeriod The period during which these tokens will be released.
     * @param value The amount of tokens to be locked.
     */
    function lock(address account, uint256 lockReleasePeriod, uint256 value) public override onlyOwner {
        _lockInternal(account, lockReleasePeriod, value);
    }

    /**
     * @dev Internal function to lock tokens for a specified period.
     * @param account The address of the account whose tokens are to be locked.
     * @param lockReleasePeriod The period during which these tokens will be released.
     * @param value The amount of tokens to be locked.
     */
    function _lockInternal(address account, uint256 lockReleasePeriod, uint256 value) internal {
        _mint(account, lockReleasePeriod, value, "");
    }

    /**
     * @notice Previews the amount of tokens that can be unlocked for a specific account and release period.
     * @param account The address of the account whose tokens are to be unlocked.
     * @param lockReleasePeriod The period during which these tokens will be released.
     * @return The amount of tokens that can be unlocked.
     */
    function previewUnlock(address account, uint256 lockReleasePeriod) public view override returns (uint256) {
        if (currentPeriod >= lockReleasePeriod) {
            return getLockedAmount(account, lockReleasePeriod);
        } else {
            return 0;
        }
    }

    /**
     * @notice Unlocks a specified amount of tokens for a particular account once the lock release period has been reached.
     * @param account The address of the account whose tokens are to be unlocked.
     * @param lockReleasePeriod The period during which these tokens will be released.
     * @param value The amount of tokens to be unlocked.
     */
    function unlock(address account, uint256 lockReleasePeriod, uint256 value) public onlyOwner {
        _unlockInternal(account, lockReleasePeriod, value);
    }

    /**
     * @dev Internal function to unlock tokens for a specific period.
     * @param account The address of the account whose tokens are to be unlocked.
     * @param lockReleasePeriod The period during which these tokens will be released.
     * @param value The amount of tokens to be unlocked.
     */
    function _unlockInternal(address account, uint256 lockReleasePeriod, uint256 value) internal {
        if (currentPeriod < lockReleasePeriod) {
            revert LockDurationNotExpired(currentPeriod, lockReleasePeriod);
        }

        uint256 unlockableAmount = previewUnlock(account, lockReleasePeriod);
        if (unlockableAmount < value) {
            revert InsufficientLockedBalance(unlockableAmount, value);
        }

        _burn(account, lockReleasePeriod, value);
    }

    /**
     * @notice Rolls over a specified amount of unlocked tokens for a new lock period.
     * @param account The address of the account whose tokens are to be rolled over.
     * @param lockReleasePeriod The period during which these tokens will be released.
     * @param value The amount of tokens to be rolled over.
     */
    function rolloverUnlocked(address account, uint256 lockReleasePeriod, uint256 value)
        public
        virtual
        override
        onlyOwner
    {
        uint256 unlockableAmount = this.previewUnlock(account, lockReleasePeriod);

        if (value > unlockableAmount) {
            revert InsufficientLockedBalance(unlockableAmount, value);
        }

        _burn(account, lockReleasePeriod, value);

        uint256 rolloverLockReleasePeriod = lockReleasePeriod + lockDuration;

        _mint(account, rolloverLockReleasePeriod, value, "");
    }

    /**
     * @dev Updates the state when tokens are transferred.
     */
    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        override(ERC1155, ERC1155Supply)
    {
        ERC1155Supply._update(from, to, ids, values);
    }

    /**
     * @notice Returns the current period of the lock.
     * @return The current period.
     */
    function getCurrentPeriod() public view returns (uint256) {
        return currentPeriod;
    }

    /**
     * @notice Sets the current period of the lock.
     * @param _currentPeriod The new current period.
     */
    function setCurrentPeriod(uint256 _currentPeriod) public virtual {
        currentPeriod = _currentPeriod;
    }
}
