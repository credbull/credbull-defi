# TripleRateYieldStrategy
[Git Source](https://github.com/credbull/credbull-defi/blob/13cb4799ededd36005edfceebdf3ecc72e5835f9/src/yield/strategy/TripleRateYieldStrategy.sol)

**Inherits:**
[AbstractYieldStrategy](/src/yield/strategy/AbstractYieldStrategy.sol/abstract.AbstractYieldStrategy.md)

*Calculates returns using 1 'full' rate and 2 'reduced' rates, applied according to the Tenor Period, and
depending on the holding period.*


## Functions
### calcYield

Returns the yield for `principal` over the time period from `fromTimePeriod` to `toTimePeriod`.

*Reverts with [IYieldStrategy_InvalidContextAddress] is `contextContract` is invalid.
Reverts with [IYieldStrategy_InvalidPeriodRange] if the `fromTimePeriod` and `toTimePeriod` do not form a valid
Period Range.*


```solidity
function calcYield(address contextContract, uint256 principal, uint256 fromPeriod, uint256 toPeriod)
    public
    view
    virtual
    returns (uint256 yield);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`contextContract`|`address`|The [address] of the contract providing additional data required for the calculation.|
|`principal`|`uint256`|The principal amount to calculate the yield for.|
|`fromPeriod`|`uint256`||
|`toPeriod`|`uint256`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`yield`|`uint256`|The calculated yield.|


### calcPrice

Returns the price after `numTimePeriodsElapsed`.

*Reverts with [IYieldStrategy_InvalidContextAddress] is `contextContract` is invalid.*


```solidity
function calcPrice(address contextContract, uint256 numPeriodsElapsed) public view virtual returns (uint256 price);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`contextContract`|`address`|The [address] of the contract providing additional data required for the calculation.|
|`numPeriodsElapsed`|`uint256`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`price`|`uint256`|The calculated Price.|


### _noOfFullRatePeriods

Calculates the number of 'full' Interest Rate Periods.


```solidity
function _noOfFullRatePeriods(uint256 noOfPeriodsForFullRate_, uint256 from_, uint256 to_)
    internal
    pure
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`noOfPeriodsForFullRate_`|`uint256`| The number of periods that apply for the 'full' Interest Rate.|
|`from_`|`uint256`|The from period|
|`to_`|`uint256`|The to period|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The calculated number of 'full' Interest Rate Periods.|


### _firstReducedRatePeriod

Calculates the first 'reduced' Interest Rate Period after the `_from` period.

*Encapsulates the algorithm that determines the first 'reduced' Interest Rate Period. Given that `from_`
period is INCLUSIVE, this means the calculation, IFF there are 'full' Interest Rate periods, is:
`from_` + `noOfFullRatePeriods_`
Otherwise, it is simply the `from_` value.*


```solidity
function _firstReducedRatePeriod(uint256 noOfFullRatePeriods_, uint256 from_) internal pure returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`noOfFullRatePeriods_`|`uint256`| The number of Full Rate Periods|
|`from_`|`uint256`| The from period.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The calculated first Reduced Rate Period.|


