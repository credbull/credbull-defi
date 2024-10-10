# Vault
[Git Source](https://github.com/credbull/credbull-defi/blob/13cb4799ededd36005edfceebdf3ecc72e5835f9/src/vault/Vault.sol)

**Inherits:**
ERC4626, Pausable

The family defining contract, based upon Open Zeppelin's ERC4626 implementation.

*Uses a Custodian Account to accummulate the deposited Asset.*


## State Variables
### CUSTODIAN
Address of the CUSTODIAN to receive the assets on deposit and mint


```solidity
address public immutable CUSTODIAN;
```


### totalAssetDeposited
*The assets deposited to the vault will be sent to CUSTODIAN address so this is
separate variable to track the total assets that's been deposited to this vault.*


```solidity
uint256 public totalAssetDeposited;
```


### VAULT_DECIMALS
The vault decimal which is same as the asset decimal


```solidity
uint8 public immutable VAULT_DECIMALS;
```


### MAX_DECIMAL
Max decimal value supported by the vault


```solidity
uint8 public constant MAX_DECIMAL = 18;
```


### MIN_DECIMAL
Min decimal value supported by vault


```solidity
uint8 public constant MIN_DECIMAL = 6;
```


## Functions
### onDepositOrMint

Modifier to add additional checks on _deposit, the deposit/mint common workflow function.


```solidity
modifier onDepositOrMint(address caller, address receiver, uint256 assets, uint256 shares) virtual;
```

### onWithdrawOrRedeem

Modifier to add additional checks on _withdraw, the withdraw/redeem common workflow function.


```solidity
modifier onWithdrawOrRedeem(address caller, address receiver, address owner, uint256 assets, uint256 shares) virtual;
```

### constructor


```solidity
constructor(VaultParams memory params) ERC4626(params.asset) ERC20(params.shareName, params.shareSymbol);
```

### _deposit

*- The internal deposit function of ERC4626 overridden to transfer the asset to CUSTODIAN wallet
and update the _totalAssetDeposited on deposit/mint*


```solidity
function _deposit(address caller, address receiver, uint256 assets, uint256 shares)
    internal
    virtual
    override
    onDepositOrMint(caller, receiver, assets, shares)
    whenNotPaused;
```

### _withdraw

*- The internal withdraw function of ERC4626 overridden to update the _totalAssetDeposited on withdraw/redeem*


```solidity
function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
    internal
    virtual
    override
    onWithdrawOrRedeem(caller, receiver, owner, assets, shares)
    whenNotPaused;
```

### totalAssets

- Returns the total assets deposited into the vault

*- The function is overridden to return the _totalAssetDeposited value to calculate shares.*


```solidity
function totalAssets() public view override returns (uint256);
```

### _checkValidDecimalValue

Check decimal value of the asset and token used in the vaults.


```solidity
function _checkValidDecimalValue(address token) internal view returns (uint8);
```

### transfer

The share token should not be transferable.


```solidity
function transfer(address, uint256) public view override(ERC20, IERC20) returns (bool);
```

### transferFrom

The share token should not be transferable.


```solidity
function transferFrom(address from, address, uint256) public pure override(ERC20, IERC20) returns (bool);
```

### decimals

Decimal value of share token is same as asset token


```solidity
function decimals() public view override returns (uint8);
```

### _withdrawERC20

Withdraw any ERC20 tokens sent directly to contract.
This should be implemented by the inherited contract and should be callable only by the admin.


```solidity
function _withdrawERC20(address[] calldata _tokens, address _to) internal;
```

## Errors
### CredbullVault__InvalidCustodianAddress
Thrown when attempting to create a Credbull Vault with an invalid Custodian Address.


```solidity
error CredbullVault__InvalidCustodianAddress(address);
```

### CredbullVault__InvalidAsset
Thrown when attempting to create a Credbull Vault with a non-addressable Asset IERC20.


```solidity
error CredbullVault__InvalidAsset(IERC20);
```

### CredbullVault__TransferOutsideEcosystem

```solidity
error CredbullVault__TransferOutsideEcosystem(address);
```

### CredbullVault__InvalidAssetAmount

```solidity
error CredbullVault__InvalidAssetAmount(uint256);
```

### CredbullVault__UnsupportedDecimalValue

```solidity
error CredbullVault__UnsupportedDecimalValue(uint8);
```

## Structs
### VaultParams
The set of parameters required to create a Credbull Vault instance.


```solidity
struct VaultParams {
    IERC20 asset;
    string shareName;
    string shareSymbol;
    address custodian;
}
```

