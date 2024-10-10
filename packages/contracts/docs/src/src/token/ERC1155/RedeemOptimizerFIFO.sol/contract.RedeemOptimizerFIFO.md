# RedeemOptimizerFIFO
[Git Source](https://github.com/credbull/credbull-defi/blob/13cb4799ededd36005edfceebdf3ecc72e5835f9/src/token/ERC1155/RedeemOptimizerFIFO.sol)

**Inherits:**
[IRedeemOptimizer](/src/token/ERC1155/IRedeemOptimizer.sol/interface.IRedeemOptimizer.md)

*Optimizes the redemption of shares using a FIFO strategy.*


## State Variables
### DEFAULT_BASIS

```solidity
OptimizerBasis public immutable DEFAULT_BASIS;
```


### START_DEPOSIT_PERIOD

```solidity
uint256 public immutable START_DEPOSIT_PERIOD;
```


## Functions
### constructor


```solidity
constructor(OptimizerBasis defaultBasis, uint256 startDepositPeriod);
```

### optimize

Finds optimal deposit periods and shares to redeem.  Optimizer chooses shares or asset basis.


```solidity
function optimize(IMultiTokenVault vault, address owner, uint256 shares, uint256 assets, uint256 redeemPeriod)
    public
    view
    returns (uint256[] memory depositPeriods_, uint256[] memory sharesAtPeriods_);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`depositPeriods_`|`uint256[]`|depositPeriods Array of deposit periods to redeem from.|
|`sharesAtPeriods_`|`uint256[]`|sharesAtPeriods Array of share amounts to redeem for each deposit period.|


### optimizeRedeemShares

Finds optimal deposit periods and shares to redeem for a given share amount and redeemPeriod


```solidity
function optimizeRedeemShares(IMultiTokenVault vault, address owner, uint256 shares, uint256 redeemPeriod)
    public
    view
    returns (uint256[] memory depositPeriods_, uint256[] memory sharesAtPeriods_);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`depositPeriods_`|`uint256[]`|depositPeriods Array of deposit periods to redeem from.|
|`sharesAtPeriods_`|`uint256[]`|sharesAtPeriods Array of share amounts to redeem for each deposit period.|


### optimizeWithdrawAssets

Finds optimal deposit periods and shares to withdraw for a given asset amount and redeemPeriod

*- assets include deposit (principal) and any returns up to the redeem period*


```solidity
function optimizeWithdrawAssets(IMultiTokenVault vault, address owner, uint256 assets, uint256 redeemPeriod)
    public
    view
    returns (uint256[] memory depositPeriods, uint256[] memory sharesAtPeriods);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`depositPeriods`|`uint256[]`|Array of deposit periods to redeem from.|
|`sharesAtPeriods`|`uint256[]`|Array of share amounts to redeem for each deposit period.|


### _findAmount

Returns deposit periods and corresponding amounts (shares or assets) within the specified range.


```solidity
function _findAmount(IMultiTokenVault vault, OptimizerParams memory optimizerParams)
    internal
    view
    returns (uint256[] memory depositPeriods, uint256[] memory sharesAtPeriods);
```

### _trimToSize

Utility function that trims the specified arrays to the specified size.

*Allocates 2 arrays of size `toSize` and copies the `array1` and `array2` elements to their corresponding
trimmed version. Assumes that the parameter arrays are at least as large as `toSize`.*


```solidity
function _trimToSize(uint256 toSize, uint256[] memory toTrim1, uint256[] memory toTrim2)
    private
    pure
    returns (uint256[] memory trimmed1, uint256[] memory trimmed2);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`toSize`|`uint256`|The size to trim the arrays to.|
|`toTrim1`|`uint256[]`|The first array to trim.|
|`toTrim2`|`uint256[]`|The second array to trim.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`trimmed1`|`uint256[]`|The trimmed version of `array1`.|
|`trimmed2`|`uint256[]`|The trimmed version of `array2`.|


## Errors
### RedeemOptimizer__InvalidDepositPeriodRange

```solidity
error RedeemOptimizer__InvalidDepositPeriodRange(uint256 fromPeriod, uint256 toPeriod);
```

### RedeemOptimizer__FutureToDepositPeriod

```solidity
error RedeemOptimizer__FutureToDepositPeriod(uint256 toPeriod, uint256 currentPeriod);
```

### RedeemOptimizer__OptimizerFailed

```solidity
error RedeemOptimizer__OptimizerFailed(uint256 amountFound, uint256 amountToFind);
```

