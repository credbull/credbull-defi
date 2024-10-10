# SimpleInterestYieldStrategy
[Git Source](https://github.com/credbull/credbull-defi/blob/13cb4799ededd36005edfceebdf3ecc72e5835f9/src/yield/strategy/SimpleInterestYieldStrategy.sol)

**Inherits:**
[AbstractYieldStrategy](/src/yield/strategy/AbstractYieldStrategy.sol/abstract.AbstractYieldStrategy.md)

*Strategy where returns are calculated using SimpleInterest*


## Functions
### calcYield

*See {CalcSimpleInterest-calcInterest}*


```solidity
function calcYield(address contextContract, uint256 principal, uint256 fromPeriod, uint256 toPeriod)
    public
    view
    virtual
    returns (uint256 yield);
```

### calcPrice

*See {CalcSimpleInterest-calcPriceFromInterest}*


```solidity
function calcPrice(address contextContract, uint256 numPeriodsElapsed) public view virtual returns (uint256 price);
```

