# MaturityVault
[Git Source](https://github.com/credbull/credbull-defi/blob/13cb4799ededd36005edfceebdf3ecc72e5835f9/src/vault/MaturityVault.sol)

**Inherits:**
[Vault](/src/vault/Vault.sol/abstract.Vault.md)

**Author:**
@pasviegas

Once matured, such a vault will not accept further deposits.


## State Variables
### isMatured
Determine if the vault is matured or not.


```solidity
bool public isMatured;
```


### checkMaturity
Determine if Maturity Checking is enabled or disabled.


```solidity
bool public checkMaturity;
```


## Functions
### constructor


```solidity
constructor(MaturityVaultParams memory params) Vault(params.vault);
```

### _mature

- Method to mature the vault by by depositing back the asset from the custodian wallet with addition
yield earned.

*- _totalAssetDeposited to be updated to calculate the right amount of asset with yield in proportion to
the shares.*


```solidity
function _mature() internal;
```

### expectedAssetsOnMaturity

- Returns expected assets on maturity


```solidity
function expectedAssetsOnMaturity() public view virtual returns (uint256);
```

### mature

*- To be access controlled on inherited contract*


```solidity
function mature() public virtual;
```

### _checkVaultMaturity

- Function to check for maturity status.

*- Used in withdraw modifier to check for maturity status*


```solidity
function _checkVaultMaturity() internal view;
```

### _setMaturityCheck

Enables/disables the Maturity Check according to the [status] value.

*'Toggling' means flipping the existing state. This is simply a mutator.*


```solidity
function _setMaturityCheck(bool _setMaturityCheckStatus) internal;
```

## Events
### VaultMatured
Event emitted when the vault matures.


```solidity
event VaultMatured(uint256 indexed totalAssetDeposited);
```

### MaturityCheckUpdated
Event emitted when the maturity check is updated.


```solidity
event MaturityCheckUpdated(bool indexed checkMaturity);
```

## Errors
### CredbullVault__NotMatured
Reverts on withdraw if vault is not matured.


```solidity
error CredbullVault__NotMatured();
```

### CredbullVault__NotEnoughBalanceToMature
Reverts on mature if there is not enough balance.


```solidity
error CredbullVault__NotEnoughBalanceToMature();
```

## Structs
### MaturityVaultParams
The set of parameters for creating a [MaturityVault].abi

*Though unnecessary, we maintain the implementation pattern of a 'Params' per Vault.*


```solidity
struct MaturityVaultParams {
    VaultParams vault;
}
```

