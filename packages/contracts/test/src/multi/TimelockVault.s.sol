// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TimelockVault is ERC4626 {
    struct LockInfo {
        uint256 amount;
        uint256 releaseTime;
    }

    mapping(address => LockInfo) private _locks;
    uint256 public lockDuration;

    error SharesLocked(uint256 releaseTime);
    error TransferNotSupported();

    constructor(IERC20 asset, string memory name, string memory symbol, uint256 initialLockDuration)
        ERC4626(asset)
        ERC20(name, symbol)
    {
        lockDuration = initialLockDuration;
    }

    function setLockDuration(uint256 newLockDuration) external {
        lockDuration = newLockDuration;
    }

    function deposit(uint256 assets, address receiver) public override returns (uint256) {
        uint256 shares = super.deposit(assets, receiver);
        _locks[receiver] = LockInfo(shares, block.timestamp + lockDuration);
        return shares;
    }

    function redeem(uint256 shares, address receiver, address owner) public override returns (uint256) {
        if (block.timestamp < _locks[owner].releaseTime) {
            revert SharesLocked(_locks[owner].releaseTime);
        }
        return super.redeem(shares, receiver, owner);
    }

    function transfer(address, uint256) public pure override(ERC20, IERC20) returns (bool) {
        revert TransferNotSupported();
    }

    function transferFrom(address, address, uint256) public pure override(ERC20, IERC20) returns (bool) {
        revert TransferNotSupported();
    }

    function getLockInfo(address account) external view returns (uint256 lockedAmount, uint256 releaseTime) {
        LockInfo memory lock = _locks[account];
        return (lock.amount, lock.releaseTime);
    }

    function getLockTimeLeft(address account) external view returns (uint256) {
        if (block.timestamp >= _locks[account].releaseTime) {
            return 0;
        } else {
            return _locks[account].releaseTime - block.timestamp;
        }
    }
}
