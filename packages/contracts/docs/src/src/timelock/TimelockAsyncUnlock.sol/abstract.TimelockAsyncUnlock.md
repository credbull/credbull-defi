# TimelockAsyncUnlock
[Git Source](https://github.com/credbull/credbull-defi/blob/13cb4799ededd36005edfceebdf3ecc72e5835f9/src/timelock/TimelockAsyncUnlock.sol)

**Inherits:**
Initializable, [ITimelockAsyncUnlock](/src/timelock/ITimelockAsyncUnlock.sol/interface.ITimelockAsyncUnlock.md), ContextUpgradeable

*requestId = unlockPeriod and is unique by (accountAddress, requestId)*


## State Variables
### _noticePeriod

```solidity
uint256 private _noticePeriod;
```


### _unlockRequests

```solidity
mapping(address account => mapping(uint256 requestId => EnumerableMap.UintToUintMap)) private _unlockRequests;
```


### _depositPeriodAmountCache

```solidity
mapping(address account => EnumerableMap.UintToUintMap) private _depositPeriodAmountCache;
```


### __gap
*This empty reserved space is put in place to allow future versions to add new
variables without shifting down storage in the inheritance chain.
See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps*


```solidity
uint256[49] private __gap;
```


## Functions
### constructor


```solidity
constructor();
```

### __TimelockAsyncUnlock_init


```solidity
function __TimelockAsyncUnlock_init(uint256 noticePeriod_) internal virtual onlyInitializing;
```

### noticePeriod

*Return notice period*


```solidity
function noticePeriod() public view virtual returns (uint256 noticePeriod_);
```

### currentPeriod

*Return current time period and it should be implemented in child implementation*


```solidity
function currentPeriod() public view virtual returns (uint256 currentPeriod_);
```

### minUnlockPeriod

*Return the unlock period based on current time*


```solidity
function minUnlockPeriod() public view virtual returns (uint256 minUnlockPeriod_);
```

### lockedAmount

*Return the owner's locked token amount
It is same as owner's multi token balance at depositPeriod by default*


```solidity
function lockedAmount(address owner, uint256 depositPeriod) public view virtual returns (uint256 lockedAmount_);
```

### unlockRequestAmountByDepositPeriod

*Return the token amount that was already requested to be unlocked for depositPeriod*


```solidity
function unlockRequestAmountByDepositPeriod(address owner, uint256 depositPeriod)
    public
    view
    virtual
    returns (uint256 amount);
```

### unlockRequests

*Returns the unlock requests by owner and request id*


```solidity
function unlockRequests(address owner, uint256 requestId)
    public
    view
    virtual
    returns (uint256[] memory depositPeriods, uint256[] memory amounts);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`owner`|`address`|The address of the token owner who made the unlock request.|
|`requestId`|`uint256`|The ID of the unlock request.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`depositPeriods`|`uint256[]`|The depositPeriods that were requested to be unlocked|
|`amounts`|`uint256[]`|The amounts that were requested to be unlocked|


### unlockRequestAmount

*Return the token amount that was already requested to be unlocked for depositPeriod*


```solidity
function unlockRequestAmount(address owner, uint256 requestId) public view virtual returns (uint256 amount_);
```

### unlockRequestDepositPeriods

*Return the an array containing all the depositPeriods
WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
this function has an unbounded cost, and using it as part of a state-changing function may render the function
uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.*


```solidity
function unlockRequestDepositPeriods(address owner, uint256 requestId)
    public
    view
    virtual
    returns (uint256[] memory depositPeriods_);
```

### maxRequestUnlock

*Return the amount of owner that can be requested to be unlocked for depositPeriod
This can be calculated simply by lockedAmount - unlockRequested*


```solidity
function maxRequestUnlock(address owner, uint256 depositPeriod) public view virtual returns (uint256);
```

### requestUnlock

*Requests unlock for multiple deposit periods and amounts*


```solidity
function requestUnlock(address owner, uint256[] memory depositPeriods, uint256[] memory amounts)
    public
    virtual
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`owner`|`address`|The address of the token owner requesting the unlock|
|`depositPeriods`|`uint256[]`|The IDs of the deposit periods for which tokens are being requested to unlock|
|`amounts`|`uint256[]`|The amounts of tokens to unlock for each respective deposit period.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|requestId The ID of the unlock request and it can be used in unlock|


### unlock

every one can call this unlock function

*Unlocks amount using requestId*


```solidity
function unlock(address owner, uint256 requestId)
    public
    virtual
    returns (uint256[] memory depositPeriods, uint256[] memory amounts);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`owner`|`address`|The address of the token owner who made the unlock request|
|`requestId`|`uint256`|The ID of the unlock request generated by `requestUnlock`|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`depositPeriods`|`uint256[]`|The deposit periods of tokens that are unlocked|
|`amounts`|`uint256[]`|The amounts of tokens for each respective deposit period that are unlocked|


### _unlock

*Unlocks amount using requestId at the depositPeriod*


```solidity
function _unlock(address owner, uint256 depositPeriod, uint256 requestId, uint256 amountToUnlock) public virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`owner`|`address`|The address of the token owner who made the unlock request|
|`depositPeriod`|`uint256`|The depositPeriod to unlock|
|`requestId`|`uint256`|The ID of the unlock request generated by `requestUnlock`|
|`amountToUnlock`|`uint256`||


### _handleSingleUnlockRequest

*An internal function to request unlock for single deposit period*


```solidity
function _handleSingleUnlockRequest(address owner, uint256 depositPeriod, uint256 requestId, uint256 amount)
    internal
    virtual;
```

### _authorizeCaller

*An internal function to check if the caller is eligible to manage the unlocks of the owner
It can be overridden and new authorization logic can be written in child contracts*


```solidity
function _authorizeCaller(address caller, address owner) internal virtual;
```

### _handleUnlockValidation

*An internal function to check if unlock can be performed*


```solidity
function _handleUnlockValidation(address owner, uint256 depositPeriod, uint256 unlockPeriod) internal virtual;
```

## Errors
### TimelockAsyncUnlock__AuthorizeCallerFailed

```solidity
error TimelockAsyncUnlock__AuthorizeCallerFailed(address caller, address owner);
```

### TimelockAsyncUnlock__InvalidArrayLength

```solidity
error TimelockAsyncUnlock__InvalidArrayLength(uint256 depositPeriodsLength, uint256 amountsLength);
```

### TimelockAsyncUnlock__ExceededMaxRequestUnlock

```solidity
error TimelockAsyncUnlock__ExceededMaxRequestUnlock(
    address owner, uint256 depositPeriod, uint256 amount, uint256 maxRequestUnlockAmount
);
```

### TimelockAsyncUnlock__ExceededMaxUnlock

```solidity
error TimelockAsyncUnlock__ExceededMaxUnlock(
    address owner, uint256 depositPeriod, uint256 amount, uint256 maxUnlockAmount
);
```

### TimelockAsyncUnlock__UnlockBeforeDepositPeriod

```solidity
error TimelockAsyncUnlock__UnlockBeforeDepositPeriod(
    address caller, address owner, uint256 depositPeriod, uint256 unlockPeriod
);
```

### TimelockAsyncUnlock__UnlockBeforeUnlockPeriod

```solidity
error TimelockAsyncUnlock__UnlockBeforeUnlockPeriod(
    address caller, address owner, uint256 currentPeriod, uint256 unlockPeriod
);
```

