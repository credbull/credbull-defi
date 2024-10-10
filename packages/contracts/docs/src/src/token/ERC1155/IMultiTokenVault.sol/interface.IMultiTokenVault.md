# IMultiTokenVault
[Git Source](https://github.com/credbull/credbull-defi/blob/13cb4799ededd36005edfceebdf3ecc72e5835f9/src/token/ERC1155/IMultiTokenVault.sol)

**Inherits:**
IERC1155

*ERC4626 Vault-like interface for a vault that:
- Users deposit ERC20 assets, and the vault returns ERC1155 share tokens specific to the deposit period.
- Users redeem ERC1155 share tokens, and the vault returns the corresponding amount of ERC20 assets.
- Each deposit period has its own ERC1155 share token, allowing for time-based calculations, e.g. for returns.*


## Functions
### deposit

Deposits assets into the vault for the current deposit period.


```solidity
function deposit(uint256 assets, address receiver) external returns (uint256 shares);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`uint256`|The amount of assets to be deposited.|
|`receiver`|`address`|The address to receive the shares.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|The amount of shares returned.|


### redeemForDepositPeriod

Redeems shares for assets based on a specific deposit period.


```solidity
function redeemForDepositPeriod(uint256 shares, address receiver, address owner, uint256 depositPeriod)
    external
    returns (uint256 assets);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|The amount of shares to redeem.|
|`receiver`|`address`|The address to receive the assets.|
|`owner`|`address`|The address of the owner of the shares.|
|`depositPeriod`|`uint256`|The deposit period in which the shares were issued.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`uint256`|The equivalent amount of assets returned.|


### redeemForDepositPeriod

Redeems shares for assets based on a specific deposit and redeem period.


```solidity
function redeemForDepositPeriod(
    uint256 shares,
    address receiver,
    address owner,
    uint256 depositPeriod,
    uint256 redeemPeriod
) external returns (uint256 assets);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|The amount of shares to redeem.|
|`receiver`|`address`|The address to receive the assets.|
|`owner`|`address`|The address of the owner of the shares.|
|`depositPeriod`|`uint256`|The deposit period in which the shares were issued.|
|`redeemPeriod`|`uint256`|The period in which the shares are redeemed.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`uint256`|The equivalent amount of assets returned.|


### asset

Returns the underlying asset used by the vault.


```solidity
function asset() external view returns (address asset_);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`asset_`|`address`|The address of the underlying asset.|


### sharesAtPeriod

Returns the shares held by the owner for a specific deposit period.


```solidity
function sharesAtPeriod(address owner, uint256 depositPeriod) external view returns (uint256 shares);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`owner`|`address`|The address holding the shares.|
|`depositPeriod`|`uint256`|The deposit period in which the shares were issued.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|The amount of shares held by the owner.|


### maxDeposit

Returns the maximum amount of assets that can be deposited for the receiver.


```solidity
function maxDeposit(address receiver) external view returns (uint256 maxAssets);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`receiver`|`address`|The address to receive the shares.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`maxAssets`|`uint256`|The maximum amount of assets that can be deposited.|


### convertToSharesForDepositPeriod

Converts a given amount of assets to shares for a specific deposit period.


```solidity
function convertToSharesForDepositPeriod(uint256 assets, uint256 depositPeriod)
    external
    view
    returns (uint256 shares);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`uint256`|The amount of assets to convert.|
|`depositPeriod`|`uint256`|The period during which the shares are minted.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|The equivalent amount of shares.|


### convertToShares

Converts a given amount of assets to shares at the current period.


```solidity
function convertToShares(uint256 assets) external view returns (uint256 shares);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`uint256`|The amount of assets to convert.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|The equivalent amount of shares.|


### previewDeposit

Simulates the deposit of assets and returns the equivalent shares.


```solidity
function previewDeposit(uint256 assets) external view returns (uint256 shares);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`uint256`|The amount of assets to simulate depositing.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|The equivalent amount of shares.|


### maxRedeemAtPeriod

Returns the maximum shares that can be redeemed for a specific deposit period.


```solidity
function maxRedeemAtPeriod(address owner, uint256 depositPeriod) external view returns (uint256 maxShares);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`owner`|`address`|The address holding the shares.|
|`depositPeriod`|`uint256`|The deposit period in which the shares were issued.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`maxShares`|`uint256`|The maximum amount of shares that can be redeemed.|


### convertToAssetsForDepositPeriod

Converts shares to assets for a specific deposit period at the current redeem period.


```solidity
function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod)
    external
    view
    returns (uint256 assets);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|The amount of shares to convert.|
|`depositPeriod`|`uint256`|The period during which the shares were issued.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`uint256`|The equivalent amount of assets.|


### convertToAssetsForDepositPeriod

Converts shares to assets for a specific deposit and redeem period.


```solidity
function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod, uint256 redeemPeriod)
    external
    view
    returns (uint256 assets);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|The amount of shares to convert.|
|`depositPeriod`|`uint256`|The period during which the shares were issued.|
|`redeemPeriod`|`uint256`|The period during which the shares are redeemed.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`uint256`|The equivalent amount of assets.|


### convertToAssetsForDepositPeriodBatch

Converts shares to assets for the deposit periods at the redeem period.


```solidity
function convertToAssetsForDepositPeriodBatch(
    uint256[] memory shares,
    uint256[] memory depositPeriods,
    uint256 redeemPeriod
) external view returns (uint256[] memory assets);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256[]`|The amount of shares to convert.|
|`depositPeriods`|`uint256[]`|The periods during which the shares were issued.|
|`redeemPeriod`|`uint256`|The period during which the shares are redeemed.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`uint256[]`|The equivalent amount of assets.|


### previewRedeemForDepositPeriod

Simulates the redemption of shares and returns the equivalent assets.


```solidity
function previewRedeemForDepositPeriod(uint256 shares, uint256 depositPeriod, uint256 redeemPeriod)
    external
    view
    returns (uint256 assets);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|The amount of shares to redeem.|
|`depositPeriod`|`uint256`|The deposit period in which the shares were issued.|
|`redeemPeriod`|`uint256`|The period in which the shares are redeemed.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`uint256`|The estimated amount of assets returned.|


### previewRedeemForDepositPeriod

Simulates the redemption of shares for a specific deposit period.


```solidity
function previewRedeemForDepositPeriod(uint256 shares, uint256 depositPeriod) external view returns (uint256 assets);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|The amount of shares to redeem.|
|`depositPeriod`|`uint256`|The deposit period in which the shares were issued.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`uint256`|The estimated amount of assets returned.|


### currentPeriodsElapsed

Returns the current number of elapsed time periods since the vault started.


```solidity
function currentPeriodsElapsed() external view returns (uint256 currentPeriodsElapsed_);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`currentPeriodsElapsed_`|`uint256`|The number of elapsed time periods.|


## Events
### Deposit
The event is being emitted once user deposits.


```solidity
event Deposit(address indexed sender, address indexed receiver, uint256 depositPeriod, uint256 assets, uint256 shares);
```

### Withdraw
Emitted when a user withdraws assets from the vault.


```solidity
event Withdraw(
    address indexed sender,
    address indexed receiver,
    address indexed owner,
    uint256 depositPeriod,
    uint256 assets,
    uint256 shares
);
```

