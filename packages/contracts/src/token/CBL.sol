// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { ERC20Pausable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract CBL is ERC20, ERC20Permit, ERC20Burnable, ERC20Pausable, AccessControl {
    error CBL__MaxSupplyExceeded();
    error CBL__ZeroAddress();

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 public immutable MAX_SUPPLY;

    constructor(address _owner, address _minter, uint256 _maxSupply) ERC20("Credbull", "CBL") ERC20Permit("Credbull") {
        if (_owner == address(0) || _minter == address(0)) {
            revert CBL__ZeroAddress();
        }

        MAX_SUPPLY = _maxSupply;
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(MINTER_ROLE, _minter);
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        if (totalSupply() + amount > MAX_SUPPLY) {
            revert CBL__MaxSupplyExceeded();
        }
        _mint(to, amount);
    }

    // The following functions are overrides required by Solidity.
    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Pausable) {
        super._update(from, to, value);
    }
}
