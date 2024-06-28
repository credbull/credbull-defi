// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

<<<<<<<< HEAD:packages/contracts/test/test/token/SimpleUSDC.t.sol
/**
 * @notice A simple [ERC20] Token, used to mimic USDC in tests.
 * @dev The Symbol, Name and decimals are hard-coded, so an instance cannot represent anything other than 'sUSDC'.
 */
contract SimpleUSDC is ERC20, Ownable {
    constructor(uint256 initialSupply) ERC20("Simple USDC", "sUSDC") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }
}
