// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { CommonBase } from "forge-std/Base.sol";
import { console2 } from "forge-std/console2.sol";
import { StdChains } from "forge-std/StdChains.sol";
import { stdToml } from "forge-std/StdToml.sol";

/**
 * @notice Any script that is based upon the multi-network syntax TOML Configuration should extend this.
 *
 * @dev This contract extends [CommonBase] to avoid directly extending [Script] or [Test], where it will be used.
 */
abstract contract Configured is CommonBase, StdChains {
    using stdToml for string;

    string private _config;
    Chain private _chain;

    /// @dev Returns the loaded configuration [string], loading it if necessary.
    function config() internal returns (string memory) {
        if (bytes(_config).length == 0) {
            loadEnvironment(environment());
        }
        return _config;
    }

    /// @dev Realisations can override this function to control what [Chain] is effective.
    function chain() internal virtual returns (Chain memory) {
        if (bytes(_chain.chainAlias).length == 0) {
            _chain = getChain(block.chainid);
        }
        return _chain;
    }

    /// @dev Realisations can override this function to control what environment configuration file is loaded.
    function environment() internal view virtual returns (string memory) {
        return vm.envString("ENVIRONMENT");
    }

    /// @dev Clients can invoke this to load a specific environment.
    function loadEnvironment(string memory _environment) public {
        _config = loadConfiguration(_environment);
    }

    function loadConfiguration(string memory _environment) private view returns (string memory) {
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
}

/// @dev The [Configured] realisation for the Vaults Deployment Unit.
abstract contract VaultsConfigured is Configured {
    using stdToml for string;

    string private constant CONFIG_KEY_ADDRESS_OWNER = ".deployment.vaults.address.owner";
    string private constant CONFIG_KEY_ADDRESS_OPERATOR = ".deployment.vaults.address.operator";
    string private constant CONFIG_KEY_ADDRESS_CUSTODIAN = ".deployment.vaults.address.custodian";

    function owner() internal returns (address) {
        return config().readAddress(configKeyFor(CONFIG_KEY_ADDRESS_OWNER));
    }

    function operator() internal returns (address) {
        return config().readAddress(configKeyFor(CONFIG_KEY_ADDRESS_OPERATOR));
    }

    function custodian() internal returns (address) {
        return config().readAddress(configKeyFor(CONFIG_KEY_ADDRESS_CUSTODIAN));
    }
}

/// @dev The [Configured] realisation for the Vaults Support Deployment Unit.
abstract contract VaultsSupportConfigured is VaultsConfigured {
    using stdToml for string;

    string private constant CONFIG_KEY_DEPLOY_SUPPORT = ".deployment.vaults_support.deploy";

    function isDeploySupport() public returns (bool) {
        return config().readBool(configKeyFor(CONFIG_KEY_DEPLOY_SUPPORT));
    }
}

/// @dev The [Configured] realisation for the CBL Deployment Unit.
abstract contract CBLConfigured is Configured {
    using stdToml for string;

    string private constant CONFIG_KEY_MAX_SUPPLY = ".deployment.cbl.max_supply";
    string private constant CONFIG_KEY_ADDRESS_OWNER = ".deployment.cbl.address.owner";
    string private constant CONFIG_KEY_ADDRESS_MINTER = ".deployment.cbl.address.minter";
    uint256 internal constant PRECISION = 1e18;

    function maxSupply() internal returns (uint256) {
        return config().readUint(configKeyFor(CONFIG_KEY_MAX_SUPPLY)) * PRECISION;
    }

    function owner() internal returns (address) {
        return config().readAddress(configKeyFor(CONFIG_KEY_ADDRESS_OWNER));
    }

    function minter() internal returns (address) {
        return config().readAddress(configKeyFor(CONFIG_KEY_ADDRESS_MINTER));
    }
}
