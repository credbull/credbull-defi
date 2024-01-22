// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract AKYCProvider {
    function status(address receiver) public view virtual returns (bool);

    function updateStatus(address[] calldata _addresses, bool[] calldata _statuses) external virtual;
}
