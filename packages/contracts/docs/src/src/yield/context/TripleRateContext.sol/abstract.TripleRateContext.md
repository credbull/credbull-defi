# TripleRateContext
[Git Source](https://github.com/credbull/credbull-defi/blob/13cb4799ededd36005edfceebdf3ecc72e5835f9/src/yield/context/TripleRateContext.sol)

**Inherits:**
Initializable, [CalcInterestMetadata](/src/yield/CalcInterestMetadata.sol/abstract.CalcInterestMetadata.md), [ITripleRateContext](/src/yield/context/ITripleRateContext.sol/interface.ITripleRateContext.md)

*This is an abstract contract intended to be inherited from and overriden with Access Control functionality.*


## State Variables
### TENOR
The Tenor, or Maturity Period, of this context.


```solidity
uint256 public TENOR;
```


### _current
The [PeriodRate] that is currently in effect.

*When this is set, the existing value is pushed to the `_previous` [PeriodRate], thus maintaining a 2 Tenor
Period 'history', for calculating yield correctly.
This is only mutated by internal functions and is access controlled to the Operator user.*


```solidity
PeriodRate internal _current;
```


### _previous
The [PeriodRate] that was previously in effect.

*This is only mutated by internal functions and is access controlled to the Operator user.*


```solidity
PeriodRate internal _previous;
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

### __TripleRateContext_init


```solidity
function __TripleRateContext_init(ContextParams memory params) internal onlyInitializing;
```

### numPeriodsForFullRate

Returns the number of periods required to earn the full rate.


```solidity
function numPeriodsForFullRate() public view returns (uint256 numPeriods);
```

### currentPeriodRate

Returns the [PeriodRate] of the current (at invocation) Reduced Interest Rate and its
associated Period.


```solidity
function currentPeriodRate() public view override returns (PeriodRate memory currentPeriodRate_);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`currentPeriodRate_`|`PeriodRate`|The current [PeriodRate].|


### previousPeriodRate

Returns the [PeriodRate] of the previous Reduced Interest Rate and its associated Period.

*When the current [PeriodRate] is set, its existing value becomes the previous [PeriodRate].*


```solidity
function previousPeriodRate() public view override returns (PeriodRate memory previousPeriodRate_);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`previousPeriodRate_`|`PeriodRate`|The previous [PeriodRate].|


### setReducedRate

Sets the 'reduced' Interest Rate to be effective from the `effectiveFromPeriod_` Period.

*Reverts with [TripleRateContext_PeriodRegressionNotAllowed] if `effectiveFromPeriod_` is before the
current Period.
Emits [CurrentPeriodRateChanged] upon mutation. Access is `virtual` to enable Access Control override.*


```solidity
function setReducedRate(uint256 reducedRateScaled_, uint256 effectiveFromPeriod_) public virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`reducedRateScaled_`|`uint256`|The scaled 'reduced' Interest Rate percentage.|
|`effectiveFromPeriod_`|`uint256`|The Period from which the `reducedRateScaled_` is effective.|


### _setReducedRate

*A private convenience function for setting the  specified 'reduced' Interest Rate [PeriodRate] without
Effective Period regression checks.
Emits [CurrentPeriodRateChanged] upon success.*


```solidity
function _setReducedRate(PeriodRate memory candidate_) private;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`candidate_`|`PeriodRate`|The [PeriodRate] to set.|


## Events
### CurrentTenorPeriodAndRateChanged
Emits when the current Tenor Period is set, with its associated Reduced Rate.


```solidity
event CurrentTenorPeriodAndRateChanged(uint256 tenorPeriod, uint256 reducedRate);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tenorPeriod`|`uint256`|The updated current Tenor Period.|
|`reducedRate`|`uint256`|The updated Reduced Rate for the Tenor Period.|

### CurrentPeriodRateChanged
Emits when the current [TenorPeriodRate] is set.


```solidity
event CurrentPeriodRateChanged(uint256 interestRate, uint256 effectiveFromPeriod);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`interestRate`|`uint256`|The updated reduced Interest Rate.|
|`effectiveFromPeriod`|`uint256`|The updated period.|

## Errors
### TripleRateContext_TenorPeriodRegressionNotAllowed
Reverts when the Tenor Period is before the currently set Tenor Period.


```solidity
error TripleRateContext_TenorPeriodRegressionNotAllowed(uint256 tenorPeriod, uint256 newTenorPeriod);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tenorPeriod`|`uint256`|The current Tenor Period.|
|`newTenorPeriod`|`uint256`|The attempted update Tenor Period.|

### TripleRateContext_PeriodRegressionNotAllowed
Reverts when the Period is before the currently set Period.


```solidity
error TripleRateContext_PeriodRegressionNotAllowed(uint256 currentPeriod, uint256 updatePeriod);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`currentPeriod`|`uint256`|The current Period.|
|`updatePeriod`|`uint256`|The attempted update Period.|

## Structs
### ContextParams
Constructor parameters encapsulated in a struct.


```solidity
struct ContextParams {
    uint256 fullRateScaled;
    PeriodRate initialReducedRate;
    uint256 frequency;
    uint256 tenor;
    uint256 decimals;
}
```

