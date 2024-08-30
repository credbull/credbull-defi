// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { console2 as console } from "forge-std/console2.sol";

import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";

/**
 * @notice A vault that applies a time lock to `shares`, preventing withdrawal until the lock expiry.
 * @dev This vault maintains a list of share amounts with an associated Lock Time. On withdrawal of a `shares` amount,
 *  we attempt to match that amount by using all unlocked share amounts available, leaving a 'remainder' share amount,
 *  where necessary.
 */
contract BatchTimeLockVault is ERC4626 {
    using Math for uint256;

    event LockDurationChanged(uint256 _from, uint256 _to);

    /**
     * @notice Denotes that a sufficient amount of unlocked shares are not available for redemption.
     * @param maxRedeemable The amount of shares that is currently redeemable.
     */
    error SharesLocked(uint256 maxRedeemable);

    struct Locked {
        uint256 shares;
        uint256 lockedUntil;
    }

    uint256 public lockDuration;
    uint256 private _totalSupply;

    /// @dev The User/Client to Array of [Locked].
    // NOTE (JL,2024-08-21): Dynamic array. Is this storage? Or do I need to 'new' it?
    // NOTE (JL,2024-08-21): The array will be inherently time ordered
    mapping(address => Locked[]) public locksByDepositer;

    constructor(
        IERC20 asset,
        uint256 lockDuration_,
        uint256 totalSupply_
    ) ERC4626(asset) ERC20("Batch Time Lock Claim", "BTLC") {
        _totalSupply = totalSupply_;
        lockDuration = lockDuration_;
    }

    function totalSupply() public view override(ERC20, IERC20) returns (uint256) {
        return _totalSupply;
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

        console.log("Assets=", assets, ", Shares=", shares);

        // NOTE (JL,2024-08-21): Locked Until should fall within a Deposit Window. Normalised to midnight?
        locksByDepositer[receiver].push(Locked(shares, block.timestamp + lockDuration));

        return shares;
    }

    function redeem(uint256 shares, address receiver, address owner) public override returns (uint256) {
        Locked[] storage locks = locksByDepositer[owner];
        uint8[] memory selected = new uint8[](locks.length);
        uint8 selectedIndex = 0;
        uint256 selectedSummed;
        bool isRedeemSatisfied = false;

        for (uint8 i = 0; i <= locks.length - 1 && !isRedeemSatisfied; i++) {
            // If this lock is expired, check if it is enough shares.
            if (locks[i].lockedUntil <= block.timestamp) {
                // If the summation of previous locks plus this lock satisfies the redeem amount, process it.
                if (selectedSummed + locks[i].shares >= shares) {
                    // Calculate any remainder to update the current Lock with.
                    uint256 remainder = (selectedSummed + locks[i].shares) - shares;

                    // If the remainder is 0, then cache the index for removal.
                    if (remainder == 0) {
                        // Cache the index of the lock for post-processing.
                        selected[selectedIndex++] = i;
                    } else {
                        // Update the current Lock with the remainder value, retaining the 'lockedUntil'
                        locks[i].shares = remainder;
                    }

                    // Add the non-remainder value to the summed shares, which should now match `shares`.
                    selectedSummed += locks[i].shares - remainder;

                    // Exit the loop and satisfy the redemption
                    isRedeemSatisfied = true;
                } else {
                    // We do not satisfy the redeem. Sum the Lock's Share Amount to the total of unlocked deposits.
                    selectedSummed += locks[i].shares;

                    // Cache the index of the lock for post-processing.
                    selected[selectedIndex++] = i;
                }
            }
        }

        if (!isRedeemSatisfied) {
            revert SharesLocked(selectedSummed);
        }

        // Remove the 'selected' indices from the locks array.
        remove(selected, selectedIndex, locks);

        return super.redeem(shares, receiver, owner);
    }

    /**
     * @dev Convenience function to remove a number of index points from the [locks] array. The traversal of [locks]
     *  is from the last element to the first, driven by a reverse order iteration over the [indicesToRemove] array.
     *  Removal is done by moving the value in the index to the last element in the array and popping it.
     *
     * @param indicesToRemove An ordered array of [uint8] indices to the [locks] array to be removed.
     * @param startFrom The last populated item in [indicesToRemove] and facilitates reverse order iteration.
     * @param locks A [Locked] array to remove from.
     */
    function remove(uint8[] memory indicesToRemove, uint8 startFrom, Locked[] storage locks) private {
        for (uint256 i = startFrom; i > 0; i--) {
            for (uint256 j = indicesToRemove[i - 1]; j < locks.length - 1; j++) {
                locks[j] = locks[j + 1];
            }
            locks.pop();
        }
    }
}
