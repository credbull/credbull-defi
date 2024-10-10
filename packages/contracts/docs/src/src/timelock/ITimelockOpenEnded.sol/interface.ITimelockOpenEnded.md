# ITimelockOpenEnded
[Git Source](https://github.com/credbull/credbull-defi/blob/13cb4799ededd36005edfceebdf3ecc72e5835f9/src/timelock/ITimelockOpenEnded.sol)

*Interface for managing open-ended token locks with multiple deposit periods.
Tokens are locked indefinitely, but associated with specific deposit periods for tracking.*


## Functions
### lock

Locks `amount` of tokens for `account` at the given `depositPeriod`.


```solidity
function lock(address account, uint256 depositPeriod, uint256 amount) external;
```

### unlock

Unlocks `amount` of tokens for `account` from the given `depositPeriod`.


```solidity
function unlock(address account, uint256 depositPeriod, uint256 amount) external;
```

### lockedAmount

Returns the amount of tokens locked for `account` at the given `depositPeriod`.
MUST always be the total amount locked, even if some locks are unlocked


```solidity
function lockedAmount(address account, uint256 depositPeriod) external view returns (uint256 lockedAmount_);
```

### unlockedAmount

Returns the amount of tokens locked for `account` at the given `depositPeriod`.


```solidity
function unlockedAmount(address account, uint256 depositPeriod) external view returns (uint256 unlockedAmount_);
```

## Errors
### ITimelockOpenEnded__ExceededMaxUnlock

```solidity
error ITimelockOpenEnded__ExceededMaxUnlock(address account, uint256 amount, uint256 maxUnlock);
```

