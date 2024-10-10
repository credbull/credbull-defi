# ITripleRateContext
[Git Source](https://github.com/credbull/credbull-defi/blob/13cb4799ededd36005edfceebdf3ecc72e5835f9/src/yield/context/ITripleRateContext.sol)

**Inherits:**
[ICalcInterestMetadata](/src/yield/ICalcInterestMetadata.sol/interface.ICalcInterestMetadata.md)

*Context for yield calculations with an interest rate and dual reduced interest rates, applicable across Tenor
Periods. All rate are expressed in percentage terms and scaled using [scale()]. The 'full' rate values are
encapsulated by the [ICalcInterestMetadata].*


## Functions
### numPeriodsForFullRate

Returns the number of periods required to earn the full rate.


```solidity
function numPeriodsForFullRate() external view returns (uint256 numPeriods);
```

### currentPeriodRate

Returns the [PeriodRate] of the current (at invocation) Reduced Interest Rate and its
associated Period.


```solidity
function currentPeriodRate() external view returns (PeriodRate memory currentPeriodRate_);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`currentPeriodRate_`|`PeriodRate`|The current [PeriodRate].|


### previousPeriodRate

Returns the [PeriodRate] of the previous Reduced Interest Rate and its associated Period.

*When the current [PeriodRate] is set, its existing value becomes the previous [PeriodRate].*


```solidity
function previousPeriodRate() external view returns (PeriodRate memory previousPeriodRate_);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`previousPeriodRate_`|`PeriodRate`|The previous [PeriodRate].|


## Structs
### PeriodRate
Associates an Interest Rate with the Period from which it applies.


```solidity
struct PeriodRate {
    uint256 interestRate;
    uint256 effectiveFromPeriod;
}
```

