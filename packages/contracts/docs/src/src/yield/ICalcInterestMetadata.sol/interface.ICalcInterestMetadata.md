# ICalcInterestMetadata
[Git Source](https://github.com/credbull/credbull-defi/blob/13cb4799ededd36005edfceebdf3ecc72e5835f9/src/yield/ICalcInterestMetadata.sol)

*Interface for providing metadata required for interest calculations.*


## Functions
### frequency

Returns the frequency of interest application.


```solidity
function frequency() external view returns (uint256 frequency);
```

### rateScaled

Returns the scaled annual interest rate as a percentage.


```solidity
function rateScaled() external view returns (uint256 rateInPercentageScaled);
```

### scale

Returns the scale factor used in calculations.


```solidity
function scale() external view returns (uint256 scale);
```

