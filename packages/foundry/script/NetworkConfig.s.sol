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

contract NetworkConfigFactory is Script {
    uint256 public constant CHAINID_LOCAL = 31337;

    INetworkConfig private activeNetworkConfig;
    bool private initialized;

    error UnsupportedChainError(string msg, uint256 chainid);

    // For full chainLists see: https://chainlist.org/
    constructor() {
        // todo - list out the chains that are fine
        if (block.chainid == CHAINID_LOCAL) {
            // okay
        } else {
            revert UnsupportedChainError(
                string.concat("Unsupported chain: ", Strings.toString(block.chainid)), block.chainid
            );
        }
    }

    function createLocalNetwork(address contractOwnerAddress) public returns (INetworkConfig) {
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
