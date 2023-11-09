//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

contract StakingVault is ERC4626 {

    constructor(IERC20 asset)
    ERC4626(asset)
    ERC20("xStaking", "STK")
    {}

//    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
//        revert('TRANSFER_NOT_SUPPORTED');
//    }
//
//    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
//        revert('TRANSFER_NOT_SUPPORTED');
//    }
}
