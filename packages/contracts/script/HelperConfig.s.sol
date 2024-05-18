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

    string private config;

    bool private testMode = false;

    constructor(bool _test) {
        testMode = _test;

        config = loadConfiguration();

        if (block.chainid == 421614 || block.chainid == 80001 || block.chainid == 84532) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 31337) {
            activeNetworkConfig = getAnvilEthConfig();
        } else {
            revert(string.concat("Unsupported chain with chainId ", vm.toString(block.chainid)));
        }
    }

    function getNetworkConfig() public view returns (NetworkConfig memory) {
        return activeNetworkConfig;
    }

    function loadConfiguration() internal view returns (string memory) {
        string memory environment = vm.envString("ENVIRONMENT");
        string memory path = string.concat(vm.projectRoot(), "/resource/", environment, ".toml");
        console2.log(string.concat("Loading configuration from: ", path));
        return vm.readFile(path);
    }

    /// Create Config for Anvil (local) chain
    /// @return Network config will chain specific config
    function getSepoliaEthConfig() internal returns (NetworkConfig memory) {
        if (address(activeNetworkConfig.factoryParams.operator) != address(0)) {
            return (activeNetworkConfig);
        }

        FactoryParams memory factoryParams = createFactoryParamsFromConfig();

        // TODO - replace this with USDC and CBL actual contract addresses
        DeployMocks deployMocks = new DeployMocks(testMode, factoryParams.owner);
        (IERC20 mockToken, IERC20 mockStablecoin) = deployMocks.run();

        NetworkConfig memory sepoliaConfig =
            NetworkConfig({ factoryParams: factoryParams, usdcToken: mockStablecoin, cblToken: mockToken });

        return sepoliaConfig;
    }

    /// Create Config for Anvil (local) chain
    /// @return Network config will chain specific config
    function getAnvilEthConfig() internal returns (NetworkConfig memory) {
        if (address(activeNetworkConfig.factoryParams.operator) != address(0)) {
            return (activeNetworkConfig);
        }

        FactoryParams memory factoryParams = createFactoryParamsFromConfig();

        DeployMocks deployMocks = new DeployMocks(testMode, factoryParams.owner);
        (IERC20 mockToken, IERC20 mockStablecoin) = deployMocks.run();

        NetworkConfig memory anvilConfig =
            NetworkConfig({ factoryParams: factoryParams, usdcToken: mockStablecoin, cblToken: mockToken });

        return anvilConfig;
    }

    /// Create Config for Anvil (local) chain
    /// @return Network config will chain specific config
    function createFactoryParamsFromConfig() internal returns (FactoryParams memory) {
        FactoryParams memory factoryParams = FactoryParams({
            owner: config.readAddress(".ethereum.vm.owner.public_address"),
            operator: config.readAddress(".ethereum.vm.operator.public_address"),
            collateralPercentage: config.readUint(".application.collateral_percentage")
        });

        return factoryParams;
    }
}
