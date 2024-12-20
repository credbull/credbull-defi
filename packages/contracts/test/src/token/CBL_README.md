# CBL (Credbull) Token Contract

## Overview

The CBL token is an ERC20-compliant token with additional features such as permit, burnable, capped supply and access control. 

The CBL token extends OpenZeppelin 5.0 contracts: ERC20, ERC20Permit, ERC20Burnable, ERC20Capped and AccessControl.

## Features

- **Permit:** Allows approvals to be made via signatures, following the ERC20Permit standard.
- **Burnable:** Tokens can be burned, reducing the total supply.
- **Capped Supply:** The total supply of tokens is capped.
- **Access Control:** Roles are used to manage permissions for minting and administrative functions.

## Roles

### Admin

The Admin role is assigned to the owner of the contract and has the highest level of control. Admins can:

- Manage role assignments, including granting and revoking roles.

### Minter

The Minter role is responsible for creating new tokens. Minters can:

- Mint new tokens to specified addresses.
- Only accounts with the Minter role can call the minting function.

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

**Parameters**

| Name         | Type      | Description                                              |
|--------------|-----------|----------------------------------------------------------|
| `_owner`     | `address` | The address of the owner who will have the admin role.   |
| `_minter`    | `address` | The address of the minter who will have the minter role. |
| `_maxSupply` | `uint256` | The maximum supply of the token.                         |


### mint

Mints new tokens.

*Can only be called by an account with the minter role.*

**Parameters**

| Name     | Type      | Description                    |
|----------|-----------|--------------------------------|
| `to`     | `address` | The address to mint tokens to. |
| `amount` | `uint256` | The amount of tokens to mint.  |

### _update

*Overrides required by Solidity for multiple inheritance.*

**Parameters**

| Name    | Type      | Description                                    |
|---------|-----------|------------------------------------------------|
| `from`  | `address` | The address from which tokens are transferred. |
| `to`    | `address` | The address to which tokens are transferred.   |
| `value` | `uint256` | The amount of tokens transferred.              |

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

## Roadmap - Future Features

### Governance & Governance Token ($gCBL) Contract

Governance will be implemented in a separate Governance Token ($gCBL) smart contract.   The $gCBL contract will include functions 
related to governance and voting.  Users lock $CBL to receive Governance Tokens ($gCBL) in return.