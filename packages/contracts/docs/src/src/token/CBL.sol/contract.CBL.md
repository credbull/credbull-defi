# CBL
[Git Source](https://github.com/credbull/credbull-defi/blob/13cb4799ededd36005edfceebdf3ecc72e5835f9/src/token/CBL.sol)

**Inherits:**
ERC20, ERC20Permit, ERC20Burnable, ERC20Capped, ERC20Pausable, AccessControl

*ERC20 token with additional features: permit, burnable, capped supply, pausability, and access control.*


## State Variables
### MINTER_ROLE
Role identifier for the minter role.


```solidity
bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
```


## Functions
### constructor

Constructor to initialize the token contract.

*Sets the owner and minter roles, and initializes the capped supply.*


```solidity
constructor(address _owner, address _minter, uint256 _maxSupply)
    ERC20("Credbull", "CBL")
    ERC20Permit("Credbull")
    ERC20Capped(_maxSupply);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_owner`|`address`|The address of the owner who will have the admin role.|
|`_minter`|`address`|The address of the minter who will have the minter role.|
|`_maxSupply`|`uint256`|The maximum supply of the token.|


### pause

Pauses token transfers, minting and burning.

*Can only be called by an account with the admin role.*


```solidity
function pause() external onlyRole(DEFAULT_ADMIN_ROLE);
```

### unpause

Unpauses token transfers, minting and burning.

*Can only be called by an account with the admin role.*


```solidity
function unpause() external onlyRole(DEFAULT_ADMIN_ROLE);
```

### mint

Mints new tokens.

*Can only be called by an account with the minter role.*


```solidity
function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to`|`address`|The address to mint tokens to.|
|`amount`|`uint256`|The amount of tokens to mint.|


### _update

*Overrides required by Solidity for multiple inheritance.*


```solidity
function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Pausable, ERC20Capped);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`address`|The address from which tokens are transferred.|
|`to`|`address`|The address to which tokens are transferred.|
|`value`|`uint256`|The amount of tokens transferred.|


## Errors
### CBL__InvalidOwnerAddress
*Error to indicate that the provided owner address is invalid.*


```solidity
error CBL__InvalidOwnerAddress();
```

### CBL__InvalidMinterAddress
*Error to indicate that the provided minter address is invalid.*


```solidity
error CBL__InvalidMinterAddress();
```

