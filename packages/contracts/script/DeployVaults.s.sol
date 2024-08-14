// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";

import { CredbullFixedYieldVaultFactory } from "@credbull/CredbullFixedYieldVaultFactory.sol";
import { CredbullUpsideVaultFactory } from "@credbull/CredbullUpsideVaultFactory.sol";
import { CredbullWhiteListProvider } from "@credbull/CredbullWhiteListProvider.sol";
import { Vault } from "@credbull/vault/Vault.sol";

import { VaultsConfig } from "./TomlConfig.s.sol";
import { DeployedContracts } from "./DeployedContracts.s.sol";

/// @notice The [Script] used to deploy the Credbull Vaults Distribution.
contract DeployVaults is Script, VaultsConfig {
    /// @dev Whether to skip the deployment check, or not. By default, do not skip.
    bool private _skipDeployCheck = false;

    /**
     * @notice The `forge script` invocation entrypoint, this deploys the Vaults Distribution Unit.
     * @dev For command line invocation, the return values are ignored.
     *
     * @return fixedYieldVaultFactory The deployed [CredbullFixedYieldVaultFactory].
     * @return upsideVaultFactory The deployed [CredbullUpsideVaultFactory].
     * @return whiteListProvider The deployed [CredbullWhiteListProvider].
     */
    function run()
        external
        returns (
            CredbullFixedYieldVaultFactory fixedYieldVaultFactory,
            CredbullUpsideVaultFactory upsideVaultFactory,
            CredbullWhiteListProvider whiteListProvider
        )
    {
        address owner = owner();
        address operator = operator();
        address[] memory custodians = new address[](1);
        custodians[0] = custodian();

        DeployedContracts deployChecker = new DeployedContracts();

        vm.startBroadcast();
        if (_skipDeployCheck || deployChecker.isDeployRequired("CredbullFixedYieldVaultFactory")) {
            fixedYieldVaultFactory = new CredbullFixedYieldVaultFactory(owner, operator, custodians);
        }
        if (_skipDeployCheck || deployChecker.isDeployRequired("CredbullUpsideVaultFactory")) {
            upsideVaultFactory = new CredbullUpsideVaultFactory(owner, operator, custodians);
        }
        if (_skipDeployCheck || deployChecker.isDeployRequired("CredbullWhiteListProvider")) {
            whiteListProvider = new CredbullWhiteListProvider(operator);
        }
        vm.stopBroadcast();

        return (fixedYieldVaultFactory, upsideVaultFactory, whiteListProvider);
    }

    /// @dev A Fluent API mutator that disable the Deployment Check and returns [this] [DeployVaults].
    function skipDeployCheck() public returns (DeployVaults) {
        _skipDeployCheck = true;
        return this;
    }
}
