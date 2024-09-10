// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.23;

import { ITimelock } from "@credbull-spike/contracts/ian/interfaces/ITimelock.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { ERC1155Supply } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IRollable } from "@credbull-spike/contracts/ian/interfaces/IRollable.sol";
import { console2 } from "forge-std/console2.sol";

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
abstract contract TimelockIERC1155 is ITimelock, IRollable, ERC1155, ERC1155Supply, Ownable {
  /**
   * @dev Constructor to initialize the Timelock contract with an owner and lock duration.
   * @param _initialOwner The address of the contract owner.
   */
  constructor(address _initialOwner) ERC1155("credbull.io/funds/1") Ownable(_initialOwner) { }

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
   * @param amount The amount of tokens to be locked.
   */
  function lock(address account, uint256 lockReleasePeriod, uint256 amount) public override onlyOwner {
    _lockInternal(account, lockReleasePeriod, amount);
  }

  /**
   * @dev Internal function to lock tokens for a specified period.
   * @param account The address of the account whose tokens are to be locked.
   * @param lockReleasePeriod The period during which these tokens will be released.
   * @param amount The amount of tokens to be locked.
   */
  function _lockInternal(address account, uint256 lockReleasePeriod, uint256 amount) internal {
    _mint(account, lockReleasePeriod, amount, "");
  }

  /**
   * @notice Previews the amount of tokens that can be unlocked for a specific account and release period.
   * @param account The address of the account whose tokens are to be unlocked.
   * @param lockReleasePeriod The period during which these tokens will be released.
   * @return The amount of tokens that can be unlocked.
   */
  function previewUnlock(address account, uint256 lockReleasePeriod) public view override returns (uint256) {
    if (getCurrentPeriod() >= lockReleasePeriod) {
      return getLockedAmount(account, lockReleasePeriod);
    } else {
      return 0;
    }
  }

  /**
   * @notice Unlocks a specified amount of tokens for a particular account once the lock release period has been reached.
   * @param account The address of the account whose tokens are to be unlocked.
   * @param lockReleasePeriod The period during which these tokens will be released.
   * @param amount The amount of tokens to be unlocked.
   */
  function unlock(address account, uint256 lockReleasePeriod, uint256 amount) public onlyOwner {
    _unlockInternal(account, lockReleasePeriod, amount);
  }

  /**
   * @dev Internal function to unlock tokens for a specific period.
   * @param account The address of the account whose tokens are to be unlocked.
   * @param lockReleasePeriod The period during which these tokens will be released.
   * @param amount The amount of tokens to be unlocked.
   */
  function _unlockInternal(address account, uint256 lockReleasePeriod, uint256 amount) internal {
    uint256 currentPeriod = getCurrentPeriod();

    if (currentPeriod < lockReleasePeriod) {
      revert LockDurationNotExpired(account, currentPeriod, lockReleasePeriod);
    }

    uint256 unlockableAmount = previewUnlock(account, lockReleasePeriod);
    if (unlockableAmount < amount) {
      revert InsufficientLockedBalanceAtPeriod(account, unlockableAmount, amount, lockReleasePeriod);
    }

    _burn(account, lockReleasePeriod, amount);
  }

  /**
   * @notice Rolls over a specified amount of unlocked tokens for a new lock period.
   * @param account The address of the account whose tokens are to be rolled over.
   * @param lockReleasePeriod The period during which these tokens will be released.
   * @param amount The amount of tokens to be rolled over.
   */
  function rolloverUnlocked(
    address account,
    uint256 lockReleasePeriod,
    uint256 amount
  ) public virtual override onlyOwner {
    uint256 unlockableAmount = this.previewUnlock(account, lockReleasePeriod);
    uint256 lockDuration = getLockDuration();

    if (amount > unlockableAmount) {
      revert InsufficientLockedBalanceAtPeriod(account, unlockableAmount, amount, lockReleasePeriod);
    }

    _burn(account, lockReleasePeriod, amount);

    uint256 rolloverLockReleasePeriod = lockReleasePeriod + lockDuration;

    _mint(account, rolloverLockReleasePeriod, amount, "");
  }

  /**
   * @dev Updates the state when tokens are transferred.
   */
  function _update(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amount
  ) internal override(ERC1155, ERC1155Supply) {
    ERC1155Supply._update(from, to, ids, amount);
  }

  /**
   * @notice Returns the duration of locks.
   * How long (how many periods must elapse) before a lock can be released.
   * @return lockDuration The lock duration.
   */
  function getLockDuration() public view virtual returns (uint256 lockDuration);

  /**
   * @notice Returns the current period.
   * @dev Current period is the internal "clock" to see when a lock is unlockable.
   * @return currentPeriod The current period.
   */
  function getCurrentPeriod() public view virtual returns (uint256 currentPeriod);

  /**
   * @notice Sets the current period.
   * @dev Current period is the internal "clock" to see when a lock is unlockable.
   * @param _currentPeriod The new current period.
   */
  function setCurrentPeriod(uint256 _currentPeriod) public virtual;


  /**
   * @dev Returns lock periods for a given account where the account has a non-zero balance.
   * @param account The address of the account whose lock periods are to be retrieved.
   * @return lockPeriods An array of uint256 values representing the periods during which the account has locked tokens.
   */
  function getLockPeriods(address account) public view override returns (uint256[] memory) {
    uint256 maxLockPeriod = getCurrentPeriod() + getLockDuration() + 1;

    uint256[] memory tempLockPeriods = new uint256[](maxLockPeriod);

    uint256 accountLockCount = 0;

    // collect periods with non-zero balances
    for (uint256 i = 0; i <= maxLockPeriod; i++) {
      if (balanceOf(account, i) > 0) {
        tempLockPeriods[accountLockCount] = i;
        accountLockCount++;
      }
    }

    uint256[] memory lockPeriods = new uint256[](accountLockCount); // right-sized array for return
    for (uint256 i = 0; i < accountLockCount; i++) {
      lockPeriods[i] = tempLockPeriods[i];
    }

    return lockPeriods;
  }
}
