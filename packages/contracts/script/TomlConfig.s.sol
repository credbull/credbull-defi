// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { CommonBase } from "forge-std/Base.sol";
import { console2 } from "forge-std/console2.sol";
import { StdChains } from "forge-std/StdChains.sol";
import { stdToml } from "forge-std/StdToml.sol";

/**
 * @notice Any script that is based upon the multi-network syntax TOML Configuration should extend this.
 * @dev This contract extends [CommonBase] to avoid directly extending [Script] or [Test], where it will be used.
 */
abstract contract TomlConfig is CommonBase, StdChains {
    using stdToml for string;

    /// @notice When a sought Configuration Item is not found, revert with this error.
    error ConfigurationNotFound(string missingConfigKey);

    string private _config;
    Chain private _chain;

    /// @dev Returns the loaded configuration [string], loading it if necessary.
    function config() internal returns (string memory) {
        if (bytes(_config).length == 0) {
            loadEnvironment(environment());
        }
        return _config;
    }

    /// @dev Determines the effective [Chain], by default using the `block.chainid` value.
    function chain() internal virtual returns (Chain memory) {
        if (bytes(_chain.chainAlias).length == 0) {
            _chain = getChain(block.chainid);
        }
        return _chain;
    }

    /// @dev Determines the effective Environment Specifier, by default reading the 'ENVIRONMENT' Environment Variable.
    function environment() internal view virtual returns (string memory) {
        return vm.envString("ENVIRONMENT");
    }

    /// @dev Clients can invoke this to load a specific environment.
    function loadEnvironment(string memory _environment) public {
        _config = loadConfiguration(_environment);
    }

    /// @dev Loads the effective configuration, by default loading the Environment specific resource file.
    function loadConfiguration(string memory _environment) internal view virtual returns (string memory) {
        string memory path = string.concat(vm.projectRoot(), "/resource/", _environment, ".toml");
        console2.log(string.concat("Loading TOML configuration from: ", path));
        return vm.readFile(path);
    }

    /**
     * @notice Enables network-specific configuration overriding by key substitution.
     *
     * @dev Computes the Network Override Config Key for [configKey] and determines if that key is present in the
     * configuration. If present, returns the Network Override Config Key, if not, returns the [configKey].
     *
     * The Network Override Key is the [configKey] prefixed by `.network.chainAlias`, where
     * the Chain Alias is that of the current chain (determined by forge).
     *
     * @param configKey The [string] Configuration Key to check.
     *
     * @return The effective Configuration Key.
     */
    function configKeyFor(string memory configKey) internal returns (string memory) {
        string memory overrideKey = string.concat(".network.", chain().chainAlias, configKey);
        return vm.keyExistsToml(config(), overrideKey) ? overrideKey : configKey;
    }

    /**
     * Utility function that asserts the presence of a [configKey] value, or throws [ConfigurationNotFound].
     *
     * @param configKey The [string] Configuration Key to get.
     */
    function requireValueAt(string memory configKey) internal {
        if (!vm.keyExistsToml(config(), configKey)) {
            revert ConfigurationNotFound(configKey);
        }
    }
}

/// @dev The [TomlConfig] realisation for the Vaults Deployment Unit.
abstract contract VaultsConfig is TomlConfig {
    using stdToml for string;

    string internal constant CONFIG_KEY_ADDRESS_OWNER = ".deployment.vaults.address.owner";
    string internal constant CONFIG_KEY_ADDRESS_OPERATOR = ".deployment.vaults.address.operator";
    string internal constant CONFIG_KEY_ADDRESS_CUSTODIAN = ".deployment.vaults.address.custodian";

    function owner() internal returns (address) {
        requireValueAt(CONFIG_KEY_ADDRESS_OWNER);
        return config().readAddress(configKeyFor(CONFIG_KEY_ADDRESS_OWNER));
    }

    function operator() internal returns (address) {
        requireValueAt(CONFIG_KEY_ADDRESS_OPERATOR);
        return config().readAddress(configKeyFor(CONFIG_KEY_ADDRESS_OPERATOR));
    }

    function custodian() internal returns (address) {
        requireValueAt(CONFIG_KEY_ADDRESS_CUSTODIAN);
        return config().readAddress(configKeyFor(CONFIG_KEY_ADDRESS_CUSTODIAN));
    }
}

/// @dev The [TomlConfig] realisation for the Vaults Support Deployment Unit.
abstract contract VaultsSupportConfig is VaultsConfig {
    using stdToml for string;

    string internal constant CONFIG_KEY_DEPLOY_SUPPORT = ".deployment.vaults_support.deploy";

    function isDeploySupport() public returns (bool) {
        requireValueAt(CONFIG_KEY_DEPLOY_SUPPORT);
        return config().readBool(configKeyFor(CONFIG_KEY_DEPLOY_SUPPORT));
    }
}

/// @dev The [TomlConfig] realisation for the CBL Deployment Unit.
abstract contract CBLConfig is TomlConfig {
    using stdToml for string;

    string internal constant CONFIG_KEY_MAX_SUPPLY = ".deployment.cbl.max_supply";
    string internal constant CONFIG_KEY_ADDRESS_OWNER = ".deployment.cbl.address.owner";
    string internal constant CONFIG_KEY_ADDRESS_MINTER = ".deployment.cbl.address.minter";
    uint256 internal constant PRECISION = 1e18;

    function maxSupply() internal returns (uint256) {
        requireValueAt(CONFIG_KEY_MAX_SUPPLY);
        return config().readUint(configKeyFor(CONFIG_KEY_MAX_SUPPLY)) * PRECISION;
    }

    function owner() internal returns (address) {
        requireValueAt(CONFIG_KEY_ADDRESS_OWNER);
        return config().readAddress(configKeyFor(CONFIG_KEY_ADDRESS_OWNER));
    }

    function minter() internal returns (address) {
        requireValueAt(CONFIG_KEY_ADDRESS_MINTER);
        return config().readAddress(configKeyFor(CONFIG_KEY_ADDRESS_MINTER));
    }
}
