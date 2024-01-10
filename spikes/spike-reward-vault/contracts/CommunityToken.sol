//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract CommunityToken is ERC20, Ownable {
  constructor(uint256 initialSupply)
  ERC20("Community", "CMY")
  Ownable(msg.sender)
  {
    _mint(msg.sender, initialSupply);
  }

  function mint(address to, uint256 amount) public onlyOwner {
    _mint(to, amount);
  }
}
