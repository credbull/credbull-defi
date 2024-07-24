// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { ERC20Pausable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import { ERC20Capped } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";

contract CBL is ERC20, ERC20Permit, ERC20Burnable, ERC20Pausable, ERC20Capped, AccessControl {
    error CBL__MaxSupplyExceeded();
    error CBL__ZeroAddress();

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(address _owner, address _minter, uint256 _maxSupply)
        ERC20("Credbull", "CBL")
        ERC20Permit("Credbull")
        ERC20Capped(_maxSupply)
    {
        if (_owner == address(0) || _minter == address(0)) {
            revert CBL__ZeroAddress();
        }

        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(MINTER_ROLE, _minter);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    // The following functions are overrides required by Solidity.
    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Pausable, ERC20Capped) {
        super._update(from, to, value);
    }
}
