// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";

import { Vault } from "@credbull/vault/Vault.sol";

import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";
import { SimpleToken } from "@test/test/token/SimpleToken.t.sol";
import { SimpleVault } from "@test/test/vault/SimpleVault.t.sol";

import { VaultsSupportConfig } from "./TomlConfig.s.sol";
import { DeployedContracts } from "./DeployedContracts.s.sol";

/// @notice The [Script] for deploying the Vaults Support Distribution Unit.
contract DeployVaultsSupport is Script, VaultsSupportConfig {
    uint128 public constant MAXIMUM_SUPPLY = type(uint128).max;

    /// @dev Whether to skip the deployment check, or not. By default, do not skip.
    bool private _skipDeployCheck = false;

    /**
     * @notice The `forge script` invocation entrypoint, this deploys the Vaults Support Distribution Unit, if enabled.
     *  This comprises of a [$CBL] representative token, a [$USDC] representative stablecoin token and an example
     *  [Vault].
     * @dev For command line invocation, the return values are ignored.
     *
     * @return cbl The deployed [SimpleToken] token representing the [$CBL].
     * @return usdc The deployed [SimpleUSDC] token representing [$USDC] (i.e. a stablecoin).
     * @return vault The deployed [SimpleVault].
     */
    function run() external returns (SimpleToken cbl, SimpleUSDC usdc, SimpleVault vault) {
        if (isDeploySupport()) {
            DeployedContracts deployChecker = new DeployedContracts();

            vm.startBroadcast();
            if (_skipDeployCheck || deployChecker.isDeployRequired("SimpleToken")) {
                cbl = new SimpleToken(MAXIMUM_SUPPLY);
            }
            if (_skipDeployCheck || deployChecker.isDeployRequired("SimpleUSDC")) {
                usdc = new SimpleUSDC(MAXIMUM_SUPPLY);
            }
            if (_skipDeployCheck || deployChecker.isDeployRequired("SimpleVault")) {
                vault = new SimpleVault(
                    Vault.VaultParams({
                        asset: usdc,
                        shareName: "Simple Vault",
                        shareSymbol: "sVLT",
                        custodian: custodian()
                    })
                );
            }
            vm.stopBroadcast();
        }
        return (cbl, usdc, vault);
    }

    /// @dev A Fluent API mutator that disable the Deployment Check and returns [this] [DeployVaultsSupport].
    function skipDeployCheck() public returns (DeployVaultsSupport) {
        _skipDeployCheck = true;
        return this;
    }
}
