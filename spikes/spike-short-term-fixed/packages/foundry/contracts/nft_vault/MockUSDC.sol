//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUSDC is ERC20Permit {
  constructor(string memory name, string memory symbol) payable ERC20(name, symbol) ERC20Permit(name) { }

  function mint(address account, uint256 amount) external {
    _mint(account, amount);
  }

  function burn(address account, uint256 amount) external {
    _burn(account, amount);
  }
}
