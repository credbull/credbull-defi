// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ITimelock } from "./ITimelock.s.sol";

contract TimelockVault is ERC4626, ITimelock {
    struct LockInfo {
        uint256 amount;
        uint256 releaseTime;
    }

    mapping(address => LockInfo) private _locks;
    uint256 public lockDuration;
    uint256 internal currentTimePeriodsElapsed = 0;

    error SharesLocked(uint256 releaseTime);
    error TransferNotSupported();

    constructor(IERC20 asset, string memory name, string memory symbol, uint256 _lockDuration)
        ERC4626(asset)
        ERC20(name, symbol)
    {
        lockDuration = _lockDuration;
    }

    // Deposit and Redeem Functions

    function deposit(uint256 assets, address receiver) public override returns (uint256) {
        uint256 shares = convertToShares(assets);
        lock(receiver, lockDuration, shares);
        return super.deposit(assets, receiver);
    }

    function redeem(uint256 shares, address receiver, address owner) public override returns (uint256) {
        unlock(owner, lockDuration, shares);
        return super.redeem(shares, receiver, owner);
    }

    // ITimelock Interface Implementation

    function lock(address account, uint256 lockReleasePeriod, uint256 value) public override {
        _locks[account] = LockInfo(value, lockReleasePeriod);
    }

    function unlock(address account, uint256 lockReleasePeriod, uint256 value) public override {
        if (currentTimePeriodsElapsed < lockReleasePeriod) {
            revert LockDurationNotExpired(currentTimePeriodsElapsed, lockReleasePeriod);
        }

        uint256 lockedBalance = getLockedAmount(account, lockReleasePeriod);
        if (lockedBalance < value) {
            revert InsufficientLockedBalance(lockedBalance, value);
        }

        _locks[account].amount -= value;
    }

    function getLockedAmount(address account, uint256 lockReleasePeriod) public view override returns (uint256) {
        if (lockReleasePeriod == _locks[account].releaseTime) {
            return _locks[account].amount;
        } else {
            return 0; // Return 0 if the lock period has expired.
        }
    }

    function transfer(address, uint256) public pure override(ERC20, IERC20) returns (bool) {
        revert TransferNotSupported();
    }

    function transferFrom(address, address, uint256) public pure override(ERC20, IERC20) returns (bool) {
        revert TransferNotSupported();
    }

    function getCurrentTimePeriodsElapsed() public view returns (uint256) {
        return currentTimePeriodsElapsed;
    }

    function setCurrentTimePeriodsElapsed(uint256 _currentTimePeriodsElapsed) public {
        currentTimePeriodsElapsed = _currentTimePeriodsElapsed;
    }
}
