# VaultFactory
[Git Source](https://github.com/credbull/credbull-defi/blob/13cb4799ededd36005edfceebdf3ecc72e5835f9/src/factory/VaultFactory.sol)

**Inherits:**
AccessControl

- A factory contract to create vault contract


## State Variables
### allVaults
Address set that contains list of all vault address


```solidity
EnumerableSet.AddressSet internal allVaults;
```


### allowedCustodians
Address set that contains list of all custodian addresses


```solidity
EnumerableSet.AddressSet internal allowedCustodians;
```


### OPERATOR_ROLE
Hash for operator role


```solidity
bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
```


## Functions
### constructor


```solidity
constructor(address owner, address operator, address[] memory custodians);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`owner`|`address`|- Owner of the factory contract|
|`operator`|`address`|- Operator of the factory contract|
|`custodians`|`address[]`|- Initial set of custodians allowable for the vaults|


### onlyAllowedCustodians

Modifier to check for valid custodian address


```solidity
modifier onlyAllowedCustodians(address _custodian) virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_custodian`|`address`|- The custodian address|


### _addVault

Add vault address to the set


```solidity
function _addVault(address _vault) internal virtual;
```

### allowCustodian

Add custodian address to the set


```solidity
function allowCustodian(address _custodian) public onlyRole(DEFAULT_ADMIN_ROLE) returns (bool);
```

### removeCustodian

Remove custodian address from the set


```solidity
function removeCustodian(address _custodian) public onlyRole(DEFAULT_ADMIN_ROLE);
```

### getTotalVaultCount

Get total no.of vaults


```solidity
function getTotalVaultCount() public view returns (uint256);
```

### getVaultAtIndex

Get vault address at a given index


```solidity
function getVaultAtIndex(uint256 _index) public view returns (address);
```

### isVaultExist

Check if the vault exisits for a given address


```solidity
function isVaultExist(address _vault) public view returns (bool);
```

### isCustodianAllowed

Check if the custodian allowed for a given address


```solidity
function isCustodianAllowed(address _custodian) public view returns (bool);
```

## Events
### CustodianAllowed
Event to emit when a new custodian is allowed


```solidity
event CustodianAllowed(address indexed custodian);
```

### CustodianRemoved
Event to emit when a custodian is removed


```solidity
event CustodianRemoved(address indexed custodian);
```

## Errors
### CredbullVaultFactory__CustodianNotAllowed
Error to revert if custodian is not allowed


```solidity
error CredbullVaultFactory__CustodianNotAllowed();
```

### CredbullVaultFactory__InvalidOwnerAddress
Error to indicate that the provided owner address is invalid.


```solidity
error CredbullVaultFactory__InvalidOwnerAddress();
```

### CredbullVaultFactory__InvalidOperatorAddress
Error to indicate that the provided operator address is invalid.


```solidity
error CredbullVaultFactory__InvalidOperatorAddress();
```

### CredbullVaultFactory__InvalidCustodianAddress
Error to indicate that the provided custodian address is invalid.


```solidity
error CredbullVaultFactory__InvalidCustodianAddress();
```

