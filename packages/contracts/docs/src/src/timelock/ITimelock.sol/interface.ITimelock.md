# ITimelock
[Git Source](https://github.com/credbull/credbull-defi/blob/13cb4799ededd36005edfceebdf3ecc72e5835f9/src/timelock/ITimelock.sol)

*Interface for managing token locks with specific release periods.
Tokens are locked until a given release period, after which they can be unlocked.*


## Functions
### lock

Locks `amount` of tokens for `account` until `lockReleasePeriod`.


```solidity
function lock(address account, uint256 lockReleasePeriod, uint256 amount) external;
```

### unlock

Unlocks `amount` of tokens for `account` at `lockReleasePeriod`.


```solidity
function unlock(address account, uint256 lockReleasePeriod, uint256 amount) external;
```

### lockedAmount

Returns the amount of tokens locked for `account` at `lockReleasePeriod`.


```solidity
function lockedAmount(address account, uint256 lockReleasePeriod) external view returns (uint256 amountLocked);
```

### maxUnlock

Returns the max amount of tokens unlockable for `account` at `lockReleasePeriod`.


```solidity
function maxUnlock(address account, uint256 lockReleasePeriod) external view returns (uint256 amountUnlockable);
```

### lockPeriods

Returns the periods with locked tokens for `account` between `fromPeriod` and `toPeriod`.


```solidity
function lockPeriods(address account, uint256 fromPeriod, uint256 toPeriod)
    external
    view
    returns (uint256[] memory lockPeriods_);
```

## Errors
### ITimelock__LockDurationNotExpired

```solidity
error ITimelock__LockDurationNotExpired(address account, uint256 currentPeriod, uint256 lockReleasePeriod);
```

### ITimelock_ExceededMaxUnlock

```solidity
error ITimelock_ExceededMaxUnlock(
    address account, uint256 lockReleasePeriod, uint256 unlockAmount, uint256 maxUnlockAmount
);
```

