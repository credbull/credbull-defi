# CredbullUpsideVaultFactory
[Git Source](https://github.com/credbull/credbull-defi/blob/13cb4799ededd36005edfceebdf3ecc72e5835f9/src/CredbullUpsideVaultFactory.sol)

**Inherits:**
[VaultFactory](/src/factory/VaultFactory.sol/abstract.VaultFactory.md)


## Functions
### constructor


```solidity
constructor(address owner, address operator, address[] memory custodians) VaultFactory(owner, operator, custodians);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`owner`|`address`|- The owner of the factory contract|
|`operator`|`address`|- The operator of the factory contract|
|`custodians`|`address[]`|- The custodians allowable for the vaults|


### createVault

- Function to create a new upside vault. Should be called only by the owner


```solidity
function createVault(CredbullFixedYieldVaultWithUpside.UpsideVaultParams memory params, string memory options)
    public
    onlyRole(OPERATOR_ROLE)
    onlyAllowedCustodians(params.fixedYieldVault.maturityVault.vault.custodian)
    returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params`|`CredbullFixedYieldVaultWithUpside.UpsideVaultParams`|- The VaultParams|
|`options`|`string`|- A JSON string that contains additional info about vault (Off-chain use case)|


## Events
### VaultDeployed
Event to emit when a new vault is created


```solidity
event VaultDeployed(address indexed vault, CredbullFixedYieldVaultWithUpside.UpsideVaultParams params, string options);
```

