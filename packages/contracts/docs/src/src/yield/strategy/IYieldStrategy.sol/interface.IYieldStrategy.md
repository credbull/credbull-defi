# IYieldStrategy
[Git Source](https://github.com/credbull/credbull-defi/blob/13cb4799ededd36005edfceebdf3ecc72e5835f9/src/yield/strategy/IYieldStrategy.sol)

*Interface for calculating yield and price based on principal and elapsed time periods.*


## Functions
### calcYield

Returns the yield for `principal` over the time period from `fromTimePeriod` to `toTimePeriod`.

*Reverts with [IYieldStrategy_InvalidContextAddress] is `contextContract` is invalid.
Reverts with [IYieldStrategy_InvalidPeriodRange] if the `fromTimePeriod` and `toTimePeriod` do not form a valid
Period Range.*


```solidity
function calcYield(address contextContract, uint256 principal, uint256 fromTimePeriod, uint256 toTimePeriod)
    external
    view
    returns (uint256 yield);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`contextContract`|`address`|The [address] of the contract providing additional data required for the calculation.|
|`principal`|`uint256`|The principal amount to calculate the yield for.|
|`fromTimePeriod`|`uint256`|The period, inclusive, at the start of the Period Range.|
|`toTimePeriod`|`uint256`|The period, inclusive, at the end of the Period Range.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`yield`|`uint256`|The calculated yield.|


### calcPrice

Returns the price after `numTimePeriodsElapsed`.

*Reverts with [IYieldStrategy_InvalidContextAddress] is `contextContract` is invalid.*


```solidity
function calcPrice(address contextContract, uint256 numTimePeriodsElapsed) external view returns (uint256 price);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`contextContract`|`address`|The [address] of the contract providing additional data required for the calculation.|
|`numTimePeriodsElapsed`|`uint256`|The number of Time Periods that have elapsed at the current time.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`price`|`uint256`|The calculated Price.|


## Errors
### IYieldStrategy_InvalidContextAddress
When the `contextContract` parameter is invalid.


```solidity
error IYieldStrategy_InvalidContextAddress();
```

### IYieldStrategy_InvalidPeriodRange
When the `fromPeriod` and `toPeriod` parameters do not form a valid range.


```solidity
error IYieldStrategy_InvalidPeriodRange(uint256 from, uint256 to);
```

