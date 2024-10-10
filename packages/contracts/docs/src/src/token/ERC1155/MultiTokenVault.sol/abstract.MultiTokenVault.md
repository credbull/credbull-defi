# MultiTokenVault
[Git Source](https://github.com/credbull/credbull-defi/blob/13cb4799ededd36005edfceebdf3ecc72e5835f9/src/token/ERC1155/MultiTokenVault.sol)

**Inherits:**
Initializable, ERC1155SupplyUpgradeable, ERC1155PausableUpgradeable, [IMultiTokenVault](/src/token/ERC1155/IMultiTokenVault.sol/interface.IMultiTokenVault.md), ReentrancyGuardUpgradeable

*A vault that uses deposit-period-specific ERC1155 tokens to represent deposits.
This contract manages deposits and redemptions using ERC1155 tokens. It tracks the number
of time periods that have elapsed and allows users to deposit and redeem assets based on these periods.
Designed to be secure and production-ready for Hacken audit.*


## State Variables
### ASSET
The ERC20 token used as the underlying asset in the vault.


```solidity
IERC20 private ASSET;
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

### __MultiTokenVault_init

Initializes the vault with the asset, treasury, and token URI for ERC1155 tokens.


```solidity
function __MultiTokenVault_init(IERC20 asset_) internal onlyInitializing;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset_`|`IERC20`|The ERC20 token representing the underlying asset.|


### deposit

Deposits assets into the vault for the current deposit period.


```solidity
function deposit(uint256 assets, address receiver) public virtual override returns (uint256 shares);
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


### _depositForDepositPeriod


```solidity
function _depositForDepositPeriod(uint256 assets, address receiver, uint256 depositPeriod)
    internal
    virtual
    returns (uint256 shares);
```

### redeemForDepositPeriod

Redeems shares for assets based on a specific deposit period.


```solidity
function redeemForDepositPeriod(uint256 shares, address receiver, address owner, uint256 depositPeriod)
    public
    virtual
    returns (uint256);
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
|`<none>`|`uint256`|assets The equivalent amount of assets returned.|


### redeemForDepositPeriod

Redeems shares for assets based on a specific deposit period.


```solidity
function redeemForDepositPeriod(
    uint256 shares,
    address receiver,
    address owner,
    uint256 depositPeriod,
    uint256 redeemPeriod
) public virtual returns (uint256 assets);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|The amount of shares to redeem.|
|`receiver`|`address`|The address to receive the assets.|
|`owner`|`address`|The address of the owner of the shares.|
|`depositPeriod`|`uint256`|The deposit period in which the shares were issued.|
|`redeemPeriod`|`uint256`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`assets`|`uint256`|The equivalent amount of assets returned.|


### asset

Returns the underlying asset used by the vault.


```solidity
function asset() public view virtual returns (address asset_);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`asset_`|`address`|The address of the underlying asset.|


### sharesAtPeriod

Returns the shares held by the owner for a specific deposit period.


```solidity
function sharesAtPeriod(address owner, uint256 depositPeriod) public view returns (uint256 shares);
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
function maxDeposit(address) public view virtual returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|maxAssets The maximum amount of assets that can be deposited.|


### convertToSharesForDepositPeriod

Converts a given amount of assets to shares for a specific deposit period.


```solidity
function convertToSharesForDepositPeriod(uint256 assets, uint256 depositPeriod)
    public
    view
    virtual
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
function convertToShares(uint256 assets) public view virtual returns (uint256 shares);
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
function previewDeposit(uint256 assets) public view override returns (uint256 shares);
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
function maxRedeemAtPeriod(address owner, uint256 depositPeriod) public view virtual returns (uint256 maxShares);
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
function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod, uint256 redeemPeriod)
    public
    view
    virtual
    returns (uint256 assets);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|The amount of shares to convert.|
|`depositPeriod`|`uint256`|The period during which the shares were issued.|
|`redeemPeriod`|`uint256`||

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
) external view returns (uint256[] memory assets_);
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
|`assets_`|`uint256[]`|assets The equivalent amount of assets.|


### convertToAssetsForDepositPeriod

Converts shares to assets for a specific deposit period at the current redeem period.


```solidity
function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod) public view virtual returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`shares`|`uint256`|The amount of shares to convert.|
|`depositPeriod`|`uint256`|The period during which the shares were issued.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|assets The equivalent amount of assets.|


### previewRedeemForDepositPeriod

Simulates the redemption of shares and returns the equivalent assets.


```solidity
function previewRedeemForDepositPeriod(uint256 shares, uint256 depositPeriod, uint256 redeemPeriod)
    public
    view
    virtual
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

Simulates the redemption of shares and returns the equivalent assets.


```solidity
function previewRedeemForDepositPeriod(uint256 shares, uint256 depositPeriod)
    public
    view
    virtual
    returns (uint256 assets);
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
function currentPeriodsElapsed() public view virtual returns (uint256 currentPeriod_);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`currentPeriod_`|`uint256`|currentPeriodsElapsed_ The number of elapsed time periods.|


### supportsInterface

*Returns true if this contract implements the interface defined by `interfaceId`.
This function checks for support of the IERC1155 interface, IMultiTokenVault interface,
and delegates to the super class for any other interface support checks.*


```solidity
function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(IERC165, ERC1155Upgradeable)
    returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`interfaceId`|`bytes4`|The identifier of the interface to check for support.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|bool True if the contract supports the requested interface.|


### _deposit

*An internal function to implement the functionality of depositing assets into the vault
and mints shares for the current time period.*


```solidity
function _deposit(address caller, address receiver, uint256 depositPeriod, uint256 assets, uint256 shares)
    internal
    virtual
    nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`caller`|`address`|The address of who is depositing the assets.|
|`receiver`|`address`|The address that will receive the minted shares.|
|`depositPeriod`|`uint256`|The time period in which the assets are deposited.|
|`assets`|`uint256`|The amount of the ERC-20 underlying assets to be deposited into the vault.|
|`shares`|`uint256`|The amount of ERC-1155 tokens minted.|


### _withdraw

*Redeems the shares minted at the time of the deposit period from the vault to the owner,
while the redemption happens at the defined redeem period
And return the equivalent amount of assets to the receiver.*


```solidity
function _withdraw(
    address caller,
    address receiver,
    address owner,
    uint256 depositPeriod,
    uint256 assets,
    uint256 shares
) internal virtual nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`caller`|`address`|The address of who is redeeming the shares.|
|`receiver`|`address`|The address that will receive the minted shares.|
|`owner`|`address`|The address that owns the minted shares.|
|`depositPeriod`|`uint256`|The deposit period in which the shares were minted.|
|`assets`|`uint256`|The equivalent amount of the ERC-20 underlying assets.|
|`shares`|`uint256`|The amount of the ERC-1155 tokens to redeem.|


### _update

*See {ERC1155-_update}.*


```solidity
function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
    internal
    virtual
    override(ERC1155SupplyUpgradeable, ERC1155PausableUpgradeable)
    whenNotPaused;
```

### balanceOf

*See {IERC1155-balanceOf}.*


```solidity
function balanceOf(address account, uint256 id)
    public
    view
    virtual
    override(ERC1155Upgradeable, IERC1155)
    returns (uint256);
```

### balanceOfBatch

*See {IERC1155-balanceOfBatch}.
Requirements:
- `accounts` and `ids` must have the same length.*


```solidity
function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
    public
    view
    virtual
    override(ERC1155Upgradeable, IERC1155)
    returns (uint256[] memory);
```

### isApprovedForAll

*See {IERC1155-isApprovedForAll}.*


```solidity
function isApprovedForAll(address account, address operator)
    public
    view
    virtual
    override(ERC1155Upgradeable, IERC1155)
    returns (bool);
```

### setApprovalForAll

*See {IERC1155-setApprovalForAll}.*


```solidity
function setApprovalForAll(address operator, bool approved) public virtual override(ERC1155Upgradeable, IERC1155);
```

### safeTransferFrom

*See {IERC1155-safeTransferFrom}.*


```solidity
function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data)
    public
    virtual
    override(ERC1155Upgradeable, IERC1155);
```

### safeBatchTransferFrom

*See {IERC1155-safeBatchTransferFrom}.*


```solidity
function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
) public virtual override(ERC1155Upgradeable, IERC1155);
```

## Errors
### MultiTokenVault__ExceededMaxRedeem

```solidity
error MultiTokenVault__ExceededMaxRedeem(address owner, uint256 depositPeriod, uint256 shares, uint256 maxShares);
```

### MultiTokenVault__ExceededMaxDeposit

```solidity
error MultiTokenVault__ExceededMaxDeposit(address receiver, uint256 depositPeriod, uint256 assets, uint256 maxAssets);
```

### MultiTokenVault__RedeemTimePeriodNotSupported

```solidity
error MultiTokenVault__RedeemTimePeriodNotSupported(address owner, uint256 period, uint256 redeemPeriod);
```

### MultiTokenVault__CallerMissingApprovalForAll

```solidity
error MultiTokenVault__CallerMissingApprovalForAll(address operator, address owner);
```

### MultiTokenVault__RedeemBeforeDeposit

```solidity
error MultiTokenVault__RedeemBeforeDeposit(address owner, uint256 depositPeriod, uint256 redeemPeriod);
```

### MultiTokenVault__InvalidArrayLength

```solidity
error MultiTokenVault__InvalidArrayLength(uint256 depositPeriodsLength, uint256 sharesLength);
```

