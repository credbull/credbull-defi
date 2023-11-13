// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MockStablecoinFaucet {

    IERC20 public asset;

    constructor(IERC20 _asset) {
        asset = _asset;
    }

    function give(uint256 amount) public {
        asset.approve(msg.sender, amount);
        asset.transfer(msg.sender, amount);
    }
}
