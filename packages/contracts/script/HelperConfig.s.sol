//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { stdToml } from "forge-std/StdToml.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

import { DeployMocks } from "./DeployMocks.s.sol";
import { TomlConfig } from "./TomlConfig.s.sol";

struct FactoryParams {
    address owner;
    address operator;
    address custodian;
}

struct NetworkConfig {
    FactoryParams factoryParams;
    IERC20 cblToken;
    IERC20 usdcToken;
}

/// @title Helper to centralize any chain-specific config and code into one place
/// Each chain has different addresses for contracts such as USDC and (Gnosis) Safe
/// This is the only place in the contract code that knows about different chains and environment settings
contract HelperConfig is TomlConfig {
    using stdToml for string;

    NetworkConfig private activeNetworkConfig;

    string private tomlConfig;

    bool private testMode = false;

    constructor(bool _test) {
        testMode = _test;

        tomlConfig = loadTomlConfiguration();

        activeNetworkConfig = createNetworkConfig();
    }

    function getNetworkConfig() public view returns (NetworkConfig memory) {
        return activeNetworkConfig;
    }

    /// Creates the active Network Config, or returns it if already created.
    /// @return The active Network Config
    function createNetworkConfig() internal returns (NetworkConfig memory) {
        // NOTE (JL,2024-05-20): As function is only called from the constructor, do we need the 'exists' check?
        if (address(activeNetworkConfig.factoryParams.operator) != address(0)) {
            return (activeNetworkConfig);
        }

        FactoryParams memory factoryParams = createFactoryParamsFromConfig();

        (IERC20 cblToken, IERC20 usdcToken) = getTokensFromConfigOrDeployMocks(factoryParams.owner);

        NetworkConfig memory networkConfig =
            NetworkConfig({ factoryParams: factoryParams, usdcToken: usdcToken, cblToken: cblToken });

        return networkConfig;
    }

    /// Create the Factory Params instance from configuration.
    /// @return The active Factory Params
    function createFactoryParamsFromConfig() internal view returns (FactoryParams memory) {
        FactoryParams memory factoryParams = FactoryParams({
            owner: tomlConfig.readAddress(".evm.address.owner"),
            operator: tomlConfig.readAddress(".evm.address.operator"),
            custodian: tomlConfig.readAddress(".evm.address.custodian")
        });

        return factoryParams;
    }

    /// Fetch the CBL Token and USDC Token addresses for this chain or deploy Mock Tokens and return those
    function getTokensFromConfigOrDeployMocks(address mocksOwner)
        internal
        returns (IERC20 cblToken, IERC20 usdcToken)
    {
        string memory shouldDeployMocksKey = ".evm.deploy_mocks";
        bool shouldDeployMocks =
            vm.keyExistsToml(tomlConfig, shouldDeployMocksKey) && tomlConfig.readBool(shouldDeployMocksKey);

        if (shouldDeployMocks) {
            DeployMocks deployMocks = new DeployMocks(testMode, mocksOwner);
            return deployMocks.run();
        } else {
            address cblTokenAddr = tomlConfig.readAddress(".evm.address.cbl_token");
            address usdcTokenAddr = tomlConfig.readAddress(".evm.address.usdc_token");

            return (IERC20(cblTokenAddr), IERC20(usdcTokenAddr));
        }
    }
}
