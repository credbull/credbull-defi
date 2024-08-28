// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.23;

import { ITimelock } from "./ITimelock.s.sol";

import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { ERC1155Supply } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract TimelockIERC1155 is ITimelock, ERC1155, ERC1155Supply, Ownable {
    uint256 public lockDuration;

    uint256 public currentPeriod = 0;

    constructor(address _initialOwner, uint256 _lockDuration) ERC1155("credbull.io/funds/1") Ownable(_initialOwner) {
        lockDuration = _lockDuration;
    }

    // ======================== IERC1155 interface ========================

    function getLockedAmount(address account, uint256 lockReleasePeriod) public view returns (uint256 amountLocked) {
        return balanceOf(account, lockReleasePeriod);
    }

    function lock(address account, uint256 lockReleasePeriod, uint256 value) public override onlyOwner {
        _lockInternal(account, lockReleasePeriod, value);
    }

    // NB - this is internal.  it does not have the onlyOwner modifier
    function _lockInternal(address account, uint256 lockReleasePeriod, uint256 value) internal {
        _mint(account, lockReleasePeriod, value, "");
    }

    // TODO - need to think about this one.  this is preview for that lockReleasePeriod.
    // but we need to check every lockReleasePeriod individually to get the aggregate number
    function previewUnlock(address account, uint256 lockReleasePeriod) public view override returns (uint256) {
        if (currentPeriod >= lockReleasePeriod) {
            return getLockedAmount(account, lockReleasePeriod); // All tokens are unlocked if the current period has passed the release time.
        } else {
            return 0; // No tokens are unlocked if the current period has not reached the release time.
        }
    }

    function unlock(address account, uint256 lockReleasePeriod, uint256 value) public onlyOwner {
        _unlockInternal(account, lockReleasePeriod, value);
    }

    // NB - this is internal.  it does not have the onlyOwner modifier
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

    function rolloverUnlocked(address account, uint256 lockReleasePeriod, uint256 value) external override onlyOwner {
        uint256 unlockableAmount = this.previewUnlock(account, lockReleasePeriod);

        // Check if the account has enough unlockable tokens to roll over
        if (value > unlockableAmount) {
            revert InsufficientLockedBalance(unlockableAmount, value);
        }

        // Burn the unlocked tokens
        _burn(account, lockReleasePeriod, value);

        uint256 rolloverLockReleasePeriod = lockReleasePeriod + lockDuration;

        // Mint new tokens for the new lock period
        _mint(account, rolloverLockReleasePeriod, value, "");
    }

    // TODO - choose which to use
    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        override(ERC1155, ERC1155Supply)
    {
        // You can choose to call one of the base contract's implementations or provide your own
        ERC1155Supply._update(from, to, ids, values);
    }

    function getCurrentPeriod() public view returns (uint256) {
        return currentPeriod;
    }

    function setCurrentPeriod(uint256 _currentPeriod) public virtual {
        currentPeriod = _currentPeriod;
    }
}
