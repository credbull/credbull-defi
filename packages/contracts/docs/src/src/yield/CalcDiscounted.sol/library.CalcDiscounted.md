# CalcDiscounted
[Git Source](https://github.com/credbull/credbull-defi/blob/13cb4799ededd36005edfceebdf3ecc72e5835f9/src/yield/CalcDiscounted.sol)

*Implements the calculation of discounted principal and recovery of original principal using price.
The `calcPrincipalFromDiscounted` and `calcDiscounted` functions are mathematical inverses.
Example:
```
uint256 originalPrincipal = 200;
uint256 price = 2;
uint256 discountedValue = calcDiscounted(originalPrincipal, price); // 200 / 2 = 100
uint256 recoveredPrincipal = calcPrincipalFromDiscounted(discountedValue, price); // 100 * 2 = 200
assert(recoveredPrincipal == originalPrincipal);
```*


## Functions
### calcDiscounted

Returns the discounted principal by dividing `principal` by `price`.


```solidity
function calcDiscounted(uint256 principal, uint256 price, uint256 scale) internal pure returns (uint256 discounted);
```

### calcPrincipalFromDiscounted

Recovers the original principal by multiplying `discounted` with `price`.


```solidity
function calcPrincipalFromDiscounted(uint256 discounted, uint256 price, uint256 scale)
    internal
    pure
    returns (uint256 principal);
```

