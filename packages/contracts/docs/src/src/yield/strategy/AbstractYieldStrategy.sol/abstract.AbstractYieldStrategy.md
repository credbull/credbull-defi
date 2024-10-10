# AbstractYieldStrategy
[Git Source](https://github.com/credbull/credbull-defi/blob/13cb4799ededd36005edfceebdf3ecc72e5835f9/src/yield/strategy/AbstractYieldStrategy.sol)

**Inherits:**
[IYieldStrategy](/src/yield/strategy/IYieldStrategy.sol/interface.IYieldStrategy.md)

*Interface for calculating yield and price based on principal and elapsed time periods.*


## Functions
### _noOfPeriods

Calculate the number of periods in effect for Yield Calculation.

*Encapsulates the algorithm for determining the number of periods to calculate yield with. The
number of periods is INCLUSIVE of the `from_` period. Thus the calculation is:
noOfPeriods = (`to_` - `from_`) + 1*


```solidity
function _noOfPeriods(uint256 from_, uint256 to_) internal pure virtual returns (uint256 noOfPeriods_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from_`|`uint256`|The from period|
|`to_`|`uint256`|The to period|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`noOfPeriods_`|`uint256`|The calculated effective number of periods.|


