# CredbullFixedYieldVaultFactory
[Git Source](https://github.com/credbull/credbull-defi/blob/13cb4799ededd36005edfceebdf3ecc72e5835f9/src/CredbullFixedYieldVaultFactory.sol)

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

- Function to create a new vault. Should be called only by the owner


```solidity
function createVault(CredbullFixedYieldVault.FixedYieldVaultParams memory params, string memory options)
    public
    virtual
    onlyRole(OPERATOR_ROLE)
    onlyAllowedCustodians(params.maturityVault.vault.custodian)
    returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params`|`CredbullFixedYieldVault.FixedYieldVaultParams`|- The VaultParams|
|`options`|`string`||


## Events
### VaultDeployed
Event to emit when a new vault is created


```solidity
event VaultDeployed(address indexed vault, CredbullFixedYieldVault.FixedYieldVaultParams params, string options);
```

