// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract CredbullToken is ERC20, ERC20Burnable, Ownable {
    constructor(uint256 tokensToMint)
        ERC20("CredbullToken", "CBL")
        Ownable(msg.sender)
    {
        _mint(msg.sender, tokensToMint);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
