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

    constructor(IERC20 asset, string memory name, string memory symbol) ERC20(name, symbol) ERC4626(asset) { }

    function deposit(uint256 assets, address receiver) public override returns (uint256) {
        uint256 shares = super.deposit(assets, receiver);
        _lockShares(receiver, shares);
        return shares;
    }

    function redeem(uint256 shares, address receiver, address owner) public override returns (uint256) {
        uint256 remainingShares = shares;
        uint256 totalUnlocked = 0;

        // First, check if there are enough unlocked shares
        for (uint256 i = 0; i < lockedShares[owner].length; i++) {
            if (block.timestamp >= lockedShares[owner][i].releaseTime) {
                totalUnlocked += lockedShares[owner][i].shares;
                if (totalUnlocked >= shares) {
                    break;
                }
            }
        }

        require(totalUnlocked >= shares, "Not enough unlocked shares");

        // Then, deduct the shares from the locked amounts
        for (uint256 i = 0; i < lockedShares[owner].length && remainingShares > 0; i++) {
            if (block.timestamp >= lockedShares[owner][i].releaseTime) {
                uint256 unlockedShares = lockedShares[owner][i].shares;

                if (unlockedShares <= remainingShares) {
                    remainingShares -= unlockedShares;
                    lockedShares[owner][i].shares = 0;
                } else {
                    lockedShares[owner][i].shares -= remainingShares;
                    remainingShares = 0;
                }
            }
        }

        return super.redeem(shares, receiver, owner);
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
