# UpsideVault
[Git Source](https://github.com/credbull/credbull-defi/blob/13cb4799ededd36005edfceebdf3ecc72e5835f9/src/vault/UpsideVault.sol)

**Inherits:**
[FixedYieldVault](/src/vault/FixedYieldVault.sol/contract.FixedYieldVault.md)


## State Variables
### token
address of the Credbull token CBL


```solidity
IERC20 public token;
```


### twap

```solidity
uint256 public twap = 100_00;
```


### upsidePercentage
Percentage of collateral (100_00) is 100%


```solidity
uint256 public upsidePercentage;
```


### _upsideBalance

```solidity
mapping(address account => uint256) private _upsideBalance;
```


### MAX_PERCENTAGE
Total collateral deposited

Maximum percentage value (100%)


```solidity
uint256 private constant MAX_PERCENTAGE = 100_00;
```


### PRECISION
Precision used for math


```solidity
uint256 private constant PRECISION = 1e18;
```


### additionalPrecision
Additional precision required for math


```solidity
uint256 private additionalPrecision;
```


## Functions
### constructor


```solidity
constructor(UpsideVaultParams memory params) FixedYieldVault(params.fixedYieldVault);
```

### _deposit

*- Overridden internal deposit method to handle collateral*


```solidity
function _deposit(address caller, address receiver, uint256 assets, uint256 shares)
    internal
    override
    onDepositOrMint(caller, receiver, assets, shares)
    whenNotPaused;
```

### _withdraw

*- Overridden withdraw method to handle collateral*


```solidity
function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
    internal
    override
    onWithdrawOrRedeem(caller, receiver, owner, assets, shares)
    whenNotPaused;
```

### getCollateralAmount

- Get the collateral amount to deposit for the given asset


```solidity
function getCollateralAmount(uint256 assets) public view virtual returns (uint256);
```

### calculateTokenRedemption

- Get the collateral amount to redeem for the given shares


```solidity
function calculateTokenRedemption(uint256 shares, address account) public view virtual returns (uint256);
```

### setTWAP

- Update the twap value


```solidity
function setTWAP(uint256 _twap) public onlyRole(OPERATOR_ROLE);
```

## Errors
### CredbullVault__InsufficientShareBalance
Error to indicate that the provided share balance is insufficient.


```solidity
error CredbullVault__InsufficientShareBalance();
```

### CredbullVault__InvalidUpsidePercentage
Error to indicate that the provided collateral percentage is invalid.


```solidity
error CredbullVault__InvalidUpsidePercentage();
```

## Structs
### UpsideVaultParams

```solidity
struct UpsideVaultParams {
    FixedYieldVaultParams fixedYieldVault;
    IERC20 cblToken;
    uint256 upsidePercentage;
}
```

