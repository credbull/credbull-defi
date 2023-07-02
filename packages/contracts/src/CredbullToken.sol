// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract CredbullToken is ERC20, ERC20Burnable, Ownable {

    constructor(uint256 tokensToMint) ERC20("CredbullToken", "CBL") {
        _mint(msg.sender, tokensToMint);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}