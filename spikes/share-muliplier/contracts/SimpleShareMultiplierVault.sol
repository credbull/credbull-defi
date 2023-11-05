//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

contract SimpleShareMultiplierVault is ERC4626 {
  constructor(IERC20 asset, string memory name, string memory symbol)
  ERC4626(asset)
  ERC20(name, symbol)
  {}
}
