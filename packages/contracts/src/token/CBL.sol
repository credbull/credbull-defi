// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import { ERC20Capped } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";

/**
 * @title CBL (Credbull) Token Contract
 * @dev ERC20 token with additional features: permit, burnable, capped supply and access control.
 */
contract CBL is ERC20, ERC20Permit, ERC20Burnable, ERC20Capped, AccessControl {
    /// @dev Error to indicate that the provided owner address is invalid.
    error CBL__InvalidOwnerAddress();

    /// @dev Error to indicate that the provided minter address is invalid.
    error CBL__InvalidMinterAddress();

    /// @notice Role identifier for the minter role.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @notice Constructor to initialize the token contract.
     * @dev Sets the owner and minter roles, and initializes the capped supply.
     * @param _owner The address of the owner who will have the admin role.
     * @param _minter The address of the minter who will have the minter role.
     * @param _maxSupply The maximum supply of the token.
     */
    constructor(address _owner, address _minter, uint256 _maxSupply)
        ERC20("Credbull", "CBL")
        ERC20Permit("Credbull")
        ERC20Capped(_maxSupply)
    {
        if (_owner == address(0)) {
            revert CBL__InvalidOwnerAddress();
        }

        if (_minter == address(0)) {
            revert CBL__InvalidMinterAddress();
        }

        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(MINTER_ROLE, _minter);
    }

    /**
     * @notice Mints new tokens.
     * @dev Can only be called by an account with the minter role.
     * @param to The address to mint tokens to.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    /**
     * @dev Overrides required by Solidity for multiple inheritance.
     * @param from The address from which tokens are transferred.
     * @param to The address to which tokens are transferred.
     * @param value The amount of tokens transferred.
     */
    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Capped) {
        super._update(from, to, value);
    }
}
