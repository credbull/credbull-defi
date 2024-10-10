# CalcInterestMetadata
[Git Source](https://github.com/credbull/credbull-defi/blob/13cb4799ededd36005edfceebdf3ecc72e5835f9/src/yield/CalcInterestMetadata.sol)

**Inherits:**
Initializable, [ICalcInterestMetadata](/src/yield/ICalcInterestMetadata.sol/interface.ICalcInterestMetadata.md)

*Implements interest calculation parameters like rate, frequency, and scale.*


## State Variables
### RATE_PERCENT_SCALED

```solidity
uint256 public RATE_PERCENT_SCALED;
```


### FREQUENCY

```solidity
uint256 public FREQUENCY;
```


### SCALE

```solidity
uint256 public SCALE;
```


## Functions
### constructor


```solidity
constructor();
```

### __CalcInterestMetadata_init


```solidity
function __CalcInterestMetadata_init(uint256 ratePercentageScaled_, uint256 frequency_, uint256 decimals_)
    internal
    onlyInitializing;
```

### frequency

Returns the frequency of interest application.


```solidity
function frequency() public view virtual returns (uint256 frequency_);
```

### rateScaled

Returns the annual interest rate as a percentage, scaled.


```solidity
function rateScaled() public view virtual returns (uint256 ratePercentageScaled_);
```

### scale

Returns the scale factor for calculations (e.g., 10^18 for 18 decimals).


```solidity
function scale() public view virtual returns (uint256 scale_);
```

