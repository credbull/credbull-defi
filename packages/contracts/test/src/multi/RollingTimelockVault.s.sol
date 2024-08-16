// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

struct LockInfo {
    uint256 shares;
    uint256 releaseTime;
}

contract RollingTimelockVault is ERC4626 {
    mapping(address => LockInfo[]) private lockedShares;

    error InsufficientUnlockedShares(uint256 requested, uint256 available);

    constructor(IERC20 asset, string memory name, string memory symbol) ERC20(name, symbol) ERC4626(asset) { }

    function deposit(uint256 assets, address receiver) public override returns (uint256) {
        uint256 shares = super.deposit(assets, receiver);
        _lockShares(receiver, shares);
        return shares;
    }

    function redeem(uint256 shares, address receiver, address owner) public override returns (uint256) {
        _ensureSufficientUnlockedShares(owner, shares);
        _deductSharesFromLocks(owner, shares);

        return super.redeem(shares, receiver, owner);
    }

    function _ensureSufficientUnlockedShares(address account, uint256 shares) internal view {
        uint256 totalUnlocked = 0;

        for (uint256 i = 0; i < lockedShares[account].length; i++) {
            if (block.timestamp >= lockedShares[account][i].releaseTime) {
                totalUnlocked += lockedShares[account][i].shares;
                if (totalUnlocked >= shares) {
                    return; // Sufficient unlocked shares found, exit the function
                }
            }
        }

        // If we reach here, it means there aren't enough unlocked shares
        revert InsufficientUnlockedShares(shares, totalUnlocked);
    }

    function _deductSharesFromLocks(address account, uint256 shares) internal {
        uint256 remainingShares = shares;

        for (uint256 i = 0; i < lockedShares[account].length && remainingShares > 0; i++) {
            if (block.timestamp >= lockedShares[account][i].releaseTime) {
                uint256 unlockedShares = lockedShares[account][i].shares;

                if (unlockedShares <= remainingShares) {
                    remainingShares -= unlockedShares;
                    lockedShares[account][i].shares = 0; // Leave the lock with zero shares
                } else {
                    lockedShares[account][i].shares -= remainingShares;
                    remainingShares = 0;
                }
            }
        }
    }

    function _lockShares(address account, uint256 shares) internal returns (LockInfo memory) {
        uint256 lockDuration = 30 days;
        uint256 releaseTime = block.timestamp + lockDuration;

        // check if there is an existing lock with the same release time
        for (uint256 i = 0; i < lockedShares[account].length; i++) {
            if (lockedShares[account][i].releaseTime == releaseTime) {
                // Update the existing lock
                lockedShares[account][i].shares += shares;
                return lockedShares[account][i];
            }
        }

        LockInfo memory newLockInfo = LockInfo(shares, releaseTime);
        lockedShares[account].push(LockInfo(shares, releaseTime));
        return newLockInfo;
    }

    function getLocks(address account) public view returns (LockInfo[] memory) {
        return lockedShares[account];
    }
}
