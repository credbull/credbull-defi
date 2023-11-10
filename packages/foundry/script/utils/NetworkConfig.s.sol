// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

interface INetworkConfig {
    function getUSDC() external view returns (IERC20);

    function getCredbullVaultAsset() external view returns (IERC20);
}

contract NetworkConfig is INetworkConfig {
    IERC20 public usdc;
    IERC20 public credbullVaultAsset;

    constructor(IERC20 _usdc, IERC20 _credbullVaultAsset) {
        usdc = _usdc;
        credbullVaultAsset = _credbullVaultAsset;
    }

    function getUSDC() public view override returns (IERC20) {
        return usdc;
    }

    function getCredbullVaultAsset() public view override returns (IERC20) {
        return credbullVaultAsset;
    }
}
