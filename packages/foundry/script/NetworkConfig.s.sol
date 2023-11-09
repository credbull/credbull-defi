// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { MockStablecoin } from "../test/mocks/MockStablecoin.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { console } from "forge-std/console.sol";

import { ScaffoldETHDeploy } from "./DeployHelpers.s.sol";
import { DeployMockStablecoin } from "./mocks/DeployMockStablecoin.s.sol";


interface INetworkConfig {
    function getUSDC() external view returns (IERC20);

    function getCredbullVaultAsset() external view returns (IERC20);
}

library Addresses {
    address constant ZERO_ADDRESS = address(0);
    address constant USDC_OPTIMISM_GOERLI_ADDRESS = address(0xe05606174bac4A6364B31bd0eCA4bf4dD368f8C6);
}

contract NetworkConfigFactory is Script {
    uint256 public constant CHAINID_LOCAL = 31337;
    uint256 public constant CHAINID_OPTIMISM_GOERLI = 420;

    IERC20 public USDC_OPTIMISM_GOERLI = IERC20(Addresses.USDC_OPTIMISM_GOERLI_ADDRESS);

    INetworkConfig private activeNetworkConfig;
    bool private initialized;

    error UnsupportedChainError(string msg, uint256 chainid);

    // TODO: clean this up.  if/else not nice.  constructor arg only needed for localNetwork.
    // For full chainLists see: https://chainlist.org/
    constructor(address contractOwnerAddress) {
        // TODO: turn this into a mapping of name to supported chains
        if (block.chainid == CHAINID_LOCAL) {
            createLocalNetwork(contractOwnerAddress);
        } else if (block.chainid == CHAINID_OPTIMISM_GOERLI)  {
            createOptimismGoerli();
        } else {
            revert UnsupportedChainError(
                string.concat("NetworkConfigFactory::constructor() - Unsupported chain: ", Strings.toString(block.chainid)), block.chainid
            );
        }
    }

    function createOptimismGoerli() internal returns (INetworkConfig) {
        INetworkConfig networkConfig = new NetworkConfig(USDC_OPTIMISM_GOERLI, USDC_OPTIMISM_GOERLI);

        activeNetworkConfig = networkConfig;

        return networkConfig;
    }

    function createLocalNetwork(address contractOwnerAddress) internal returns (INetworkConfig) {
        // TODO: change these to errors and add tests
        require(
            (block.chainid == CHAINID_LOCAL),
            string.concat("Expected local network, but was ", Strings.toString(block.chainid))
        );
        require(!initialized, "NetworkConfig already initialized");
        initialized = true;

        DeployMockStablecoin deployStablecoin = new DeployMockStablecoin();
        MockStablecoin mockStablecoin = deployStablecoin.run(contractOwnerAddress);

        INetworkConfig networkConfig = new NetworkConfig(mockStablecoin, mockStablecoin);

        activeNetworkConfig = networkConfig;

        return networkConfig;
    }

    function getNetworkConfig() public view returns (INetworkConfig) {
        return activeNetworkConfig;
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
