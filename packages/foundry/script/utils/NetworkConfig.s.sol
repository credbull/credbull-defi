// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import "forge-std/Vm.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";


interface INetworkConfig {
    function getUSDC() external view returns (IERC20);

    function getCredbullVaultAsset() external view returns (IERC20);
}

contract NetworkConfigs is Script {
    mapping(uint256 => INetworkConfig) networkConfigs; // map from chainid to networkConfigs

    error NetworkConfigNotFound(string msg, uint256 chainid);

    // For full chainLists see: https://chainlist.org/

    function registerNetworkConfig(Chain memory chain, INetworkConfig networkConfig) public returns (INetworkConfig) {
        networkConfigs[chain.chainId] = networkConfig;

        return networkConfig;
    }

    function getNetworkConfig() public view returns (INetworkConfig) {
        uint256 chainId = block.chainid;

        return getNetworkConfigByChainId(chainId);
    }

    function getNetworkConfigByChain(Chain memory chain) public view returns (INetworkConfig) {
        return getNetworkConfigByChainId(chain.chainId);
    }

    function getNetworkConfigByChainId(uint256 chainId) internal view returns (INetworkConfig) {
        INetworkConfig networkConfig = networkConfigs[chainId];

        if (address(networkConfig) == address(0)) {
            revert NetworkConfigNotFound("NetworkConfig mapping not found!", chainId);
        }

        return networkConfig;
    }

    function getAddressFromEnvironment(string memory envKey) public view returns (address) {
        string memory value = vm.envString(envKey);

        address valueAddress = vm.parseAddress(value);

        return valueAddress;
    }
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
