// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { console2 as console } from "forge-std/console2.sol";

import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";

contract TimeLockVault is ERC4626 {
    using Math for uint256;

    event LockDurationChanged(uint256 _from, uint256 _to);

    error SharesLocked();

    struct Locked {
        uint256 shares;
        uint256 lockedUntil;
    }

    uint256 public lockDuration;

    /// @dev The User/Client to Array of [Locked].
    // NOTE (JL,2024-08-21): Dynamic array. Is this storage? Or do I need to 'new' it?
    // NOTE (JL,2024-08-21): The array will be inherently time ordered
    mapping(address => Locked[]) public locksByDepositer;

    constructor(IERC20 asset, uint256 lockDuration_) ERC4626(asset) ERC20("Time Lock Claim", "TLC") {
        lockDuration = lockDuration_;
    }

    function setLockDuration(uint256 lockDuration_) public {
        uint256 cached = lockDuration;
        lockDuration = lockDuration_;
        emit LockDurationChanged(cached, lockDuration_);
    }

    function getLockCountFor(address depositer) public view returns (uint256) {
        return locksByDepositer[depositer].length;
    }

    function getLockFor(address depositer, uint256 i) public view returns (uint256 shares, uint256 lockedUntil) {
        Locked memory lock = locksByDepositer[depositer][i];
        return (lock.shares, lock.lockedUntil);
    }

    function deposit(uint256 assets, address receiver) public override returns (uint256) {
        uint256 shares = super.deposit(assets, receiver);

        // NOTE (JL,2024-08-21): The Time comparison should match a whole Day. So, 'All of the nth Day' matches.
        locksByDepositer[receiver].push(Locked(shares, block.timestamp + lockDuration * 1 days));

        return shares;
    }

    function redeem(uint256 shares, address receiver, address owner) public override returns (uint256) {
        Locked[] storage locks = locksByDepositer[owner];
        uint256 foundIndex;
        bool isFound = false;
        for (uint256 i = 0; i <= locks.length - 1 && !isFound; i++) {
            // We match only on unlocked share amounts.
            // NOTE (JL,2024-08-21): Unlocked should match for a whole day. Now it matches after the specific second.
            //  This must also apply Deposit Windows.
            // NOTE (JL,2024-08-21): We will have to match the `shares` amount across multiple
            //  [Locked] instances and will have to leave a 'remainder' [Locked] once redeemed.
            if (block.timestamp > locks[i].lockedUntil && locks[i].shares == shares) {
                foundIndex = i;
                isFound = true;
            }
        }
        if (!isFound) {
            revert SharesLocked();
        }

        // Remove the found matching index by shifting it to the array end and then popping.
        for (uint256 i = foundIndex; i < locks.length - 1; i++) {
            locks[i] = locks[i + 1];
        }
        locks.pop();

        return super.redeem(shares, receiver, owner);
    }
}
