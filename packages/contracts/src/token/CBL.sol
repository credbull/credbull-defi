//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";

contract CBL is ERC20, Ownable, ERC20Permit, ERC20Burnable, Pausable {
    error CBL__MaxSupplyExceeded();

    uint256 public maxSupply;

    constructor(address _owner, uint256 _maxSupply) ERC20("Credbull", "CBL") ERC20Permit("test") Ownable(_owner) {
        maxSupply = _maxSupply;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        if (totalSupply() + amount > maxSupply) {
            revert CBL__MaxSupplyExceeded();
        }
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
}
