// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @notice A configurable [ERC20] Token that is [Ownable]. The `initialSupply` is minted to `msg.sender` on
 *  construction.
 *
 * @dev All testing [ERC20] tokens should extend this token, with reasonable default value where appropriate.
 */
contract OwnableToken is ERC20, Ownable {
    uint8 private tokenDecimals;

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 initialSupply)
        ERC20(_name, _symbol)
        Ownable(msg.sender)
    {
        tokenDecimals = _decimals;

        _mint(msg.sender, initialSupply);
    }

    function decimals() public view override returns (uint8) {
        return tokenDecimals;
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
