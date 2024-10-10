# IRedeemOptimizer
[Git Source](https://github.com/credbull/credbull-defi/blob/13cb4799ededd36005edfceebdf3ecc72e5835f9/src/token/ERC1155/IRedeemOptimizer.sol)

Interface for optimizing redemptions and withdrawals across deposit periods.


## Functions
### optimize

Finds optimal deposit periods and shares to redeem.  Optimizer chooses shares or asset basis.


```solidity
function optimize(IMultiTokenVault vault, address owner, uint256 shares, uint256 assets, uint256 redeemPeriod)
    external
    view
    returns (uint256[] memory depositPeriods, uint256[] memory sharesAtPeriods);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`depositPeriods`|`uint256[]`|Array of deposit periods to redeem from.|
|`sharesAtPeriods`|`uint256[]`|Array of share amounts to redeem for each deposit period.|


### optimizeRedeemShares

Finds optimal deposit periods and shares to redeem for a given share amount and redeemPeriod


```solidity
function optimizeRedeemShares(IMultiTokenVault vault, address owner, uint256 shares, uint256 redeemPeriod)
    external
    view
    returns (uint256[] memory depositPeriods, uint256[] memory sharesAtPeriods);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`depositPeriods`|`uint256[]`|Array of deposit periods to redeem from.|
|`sharesAtPeriods`|`uint256[]`|Array of share amounts to redeem for each deposit period.|


### optimizeWithdrawAssets

Finds optimal deposit periods and shares to withdraw for a given asset amount and redeemPeriod


```solidity
function optimizeWithdrawAssets(IMultiTokenVault vault, address owner, uint256 assets, uint256 redeemPeriod)
    external
    view
    returns (uint256[] memory depositPeriods, uint256[] memory sharesAtPeriods);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`depositPeriods`|`uint256[]`|Array of deposit periods to redeem from.|
|`sharesAtPeriods`|`uint256[]`|Array of share amounts to redeem for each deposit period.|


## Structs
### OptimizerParams

```solidity
struct OptimizerParams {
    address owner;
    uint256 amountToFind;
    uint256 fromDepositPeriod;
    uint256 toDepositPeriod;
    uint256 redeemPeriod;
    OptimizerBasis optimizerBasis;
}
```

## Enums
### OptimizerBasis

```solidity
enum OptimizerBasis {
    Shares,
    AssetsWithReturns
}
```

