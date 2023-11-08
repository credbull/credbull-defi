// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { MockStablecoin } from "../test/mocks/MockStablecoin.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { console } from "forge-std/console.sol";

import { ScaffoldETHDeploy } from "./DeployHelpers.s.sol";

interface INetworkConfig {
    function getTetherToken() external view returns (IERC20);

    function getCredbullVaultAsset() external view returns (IERC20);
}

library Addresses {
    address constant ZERO_ADDRESS = address(0);
    address constant TETHER_OPTIMISM_GOERLI_ADDRESS = address(0xe05606174bac4A6364B31bd0eCA4bf4dD368f8C6);
}

contract NetworkConfigFactory is Script {
    uint256 public constant CHAINID_LOCAL = 31337;
    uint256 public constant CHAINID_OPTIMISM_GOERLI = 420;

    IERC20 public TETHER_OPTIMISM_GOERLI = IERC20(Addresses.TETHER_OPTIMISM_GOERLI_ADDRESS);

    INetworkConfig private activeNetworkConfig;
    bool private initialized;

    error UnsupportedChainError(string msg, uint256 chainid);

    // TODO: clean this up.  if/else not nice.  constructor arg only needed for localNetwork.
    // For full chainLists see: https://chainlist.org/
    constructor(address contractOwnerAddress) {
        console.log("hello 1");

        // TODO: turn this into a mapping of name to supported chains
        if (block.chainid == CHAINID_LOCAL) {
            createLocalNetwork(contractOwnerAddress);
        } else if (block.chainid == CHAINID_OPTIMISM_GOERLI)  {
            console.log("hello 2");

            createOptimismGoerli();

            console.log("hello 2.end");
        } else {
            revert UnsupportedChainError(
                string.concat("NetworkConfigFactory::constructor() - Unsupported chain: ", Strings.toString(block.chainid)), block.chainid
            );
        }
    }

    function createOptimismGoerli() internal returns (INetworkConfig) {
        console.log("hello 3");

        INetworkConfig networkConfig = new NetworkConfig(TETHER_OPTIMISM_GOERLI, TETHER_OPTIMISM_GOERLI);

        activeNetworkConfig = networkConfig;

        console.log("hello 4");

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
        MockStablecoin mockTetherToken = deployStablecoin.run(contractOwnerAddress);

        INetworkConfig networkConfig = new NetworkConfig(mockTetherToken, mockTetherToken);

        activeNetworkConfig = networkConfig;

        return networkConfig;
    }

    function getNetworkConfig() public view returns (INetworkConfig) {
        return activeNetworkConfig;
    }
}

contract NetworkConfig is INetworkConfig {
    IERC20 public tetherToken;
    IERC20 public credbullVaultAsset;

    constructor(IERC20 _tetherToken, IERC20 _credbullVaultAsset) {
        tetherToken = _tetherToken;
        credbullVaultAsset = _credbullVaultAsset;
    }

    function getTetherToken() public view override returns (IERC20) {
        return tetherToken;
    }

    function getCredbullVaultAsset() public view override returns (IERC20) {
        return credbullVaultAsset;
    }
}

contract DeployMockStablecoin is ScaffoldETHDeploy {
    uint256 public constant BASE_TOKEN_AMOUNT = 50000;

    function run() public returns (MockStablecoin) {
        return run(msg.sender);
    }

    function run(address contractOwnerAddress) public returns (MockStablecoin) {
        vm.startBroadcast(contractOwnerAddress);

        MockStablecoin mockStablecoin = new MockStablecoin(
            BASE_TOKEN_AMOUNT
        );

        console.logString(string.concat("MockStablecoin deployed at: ", vm.toString(address(mockStablecoin))));

        vm.stopBroadcast();

        exportDeployments(); // generates file with Abi's.  call this last.

        return mockStablecoin;
    }
}
