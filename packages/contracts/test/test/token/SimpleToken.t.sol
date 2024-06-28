// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @notice A simple [ERC20] Token.
 * @dev The Symbol and Name are hard-coded, but otherwise uses the [ERC20] defaults.
 */
contract SimpleToken is ERC20, Ownable {
    constructor(uint256 initialSupply) ERC20("Simple Token", "SMPL") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
