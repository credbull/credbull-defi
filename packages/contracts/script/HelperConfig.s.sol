//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { stdToml } from "forge-std/StdToml.sol";
import { console2 } from "forge-std/console2.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

import { DeployMocks } from "./DeployMocks.s.sol";

struct FactoryParams {
    address owner;
    address operator;
    uint256 collateralPercentage; // TODO - is this required or can we remove it?
}

// TODO - add other contract addresses here, including USDC
struct NetworkConfig {
    FactoryParams factoryParams;
    IERC20 usdcToken;
    IERC20 cblToken;
}

/// @title Helper to centralize any chain-specific config and code into one place
/// Each chain has different addresses for contracts such as USDC and (Gnosis) Safe
/// This is the only place in the contract code that knows about different chains and environment settings
contract HelperConfig is Script {
    using stdToml for string;

    NetworkConfig private activeNetworkConfig;

    string private tomlConfig;

    bool private testMode = false;

    constructor(bool _test) {
        testMode = _test;

        tomlConfig = loadTomlConfiguration();

        // TODO: move to using StdChains, e.g. `getChain(block.chainid) == "Arbitrum"`
        if (
            block.chainid == 31337 || block.chainid == 421614 || block.chainid == 80001 || block.chainid == 84532
                || block.chainid == 200810
        ) {
            activeNetworkConfig = createNetworkConfig();
        } else {
            revert(string.concat("Unsupported chain with chainId ", vm.toString(block.chainid)));
        }
    }

    function getNetworkConfig() public view returns (NetworkConfig memory) {
        return activeNetworkConfig;
    }

    function loadTomlConfiguration() internal view returns (string memory) {
        string memory environment = vm.envString("ENVIRONMENT");
        string memory path = string.concat(vm.projectRoot(), "/resource/", environment, ".toml");
        console2.log(string.concat("Loading toml configuration from: ", path));
        return vm.readFile(path);
    }

    /// Creates the active Network Config, or returns it if already created.
    /// @return The active Network Config
    function createNetworkConfig() internal returns (NetworkConfig memory) {
        // NOTE (JL,2024-05-20): As function is only called from the constructor, do we need the 'exists' check?
        if (address(activeNetworkConfig.factoryParams.operator) != address(0)) {
            return (activeNetworkConfig);
        }

        FactoryParams memory factoryParams = createFactoryParamsFromConfig();

        DeployMocks deployMocks = new DeployMocks(testMode, factoryParams.owner);
        (IERC20 mockToken, IERC20 mockStablecoin) = deployMocks.run();

        NetworkConfig memory networkConfig =
            NetworkConfig({ factoryParams: factoryParams, usdcToken: mockStablecoin, cblToken: mockToken });

        return networkConfig;
    }

    /// Create the Factory Parameters instance from configuration.
    /// @return The active Factory Parameters
    function createFactoryParamsFromConfig() internal view returns (FactoryParams memory) {
        FactoryParams memory factoryParams = FactoryParams({
            owner: tomlConfig.readAddress(".evm.address.owner"),
            operator: tomlConfig.readAddress(".evm.address.operator"),
            collateralPercentage: tomlConfig.readUint(".evm.contracts.upside_vault.collateral_percentage")
        });

        return factoryParams;
    }
}
