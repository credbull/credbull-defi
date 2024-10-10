# CalcSimpleInterest
[Git Source](https://github.com/credbull/credbull-defi/blob/13cb4799ededd36005edfceebdf3ecc72e5835f9/src/yield/CalcSimpleInterest.sol)

*all functions are internal to be deployed in the same contract as caller (not a separate one)*


## Functions
### calcInterest

Calculates simple interest using `principal` ...

*function is internal to be deployed in the same contract as caller (not a separate one)*


```solidity
function calcInterest(
    uint256 principal,
    uint256 interestRatePercentScaled,
    uint256 numTimePeriodsElapsed,
    uint256 frequency,
    uint256 scale
) internal pure returns (uint256 interest);
```

### calcInterest

Calculates simple interest using `interestParams`

*function is internal to be deployed in the same contract as caller (not a separate one)*


```solidity
function calcInterest(uint256 principal, InterestParams memory interestParams)
    internal
    pure
    returns (uint256 interest);
```

### calcPriceFromInterest

Calculates the price after `numTimePeriodsElapsed`, scaled.

Price represents the accrued interest over time for a Principal of 1.


```solidity
function calcPriceFromInterest(
    uint256 interestRatePercentScaled,
    uint256 numTimePeriodsElapsed,
    uint256 frequency,
    uint256 scale
) internal pure returns (uint256 priceScaled);
```

## Errors
### PrincipalLessThanScale

```solidity
error PrincipalLessThanScale(uint256 principal, uint256 scale);
```

## Structs
### InterestParams

```solidity
struct InterestParams {
    uint256 interestRatePercentScaled;
    uint256 numTimePeriodsElapsed;
    uint256 frequency;
    uint256 scale;
}
```

