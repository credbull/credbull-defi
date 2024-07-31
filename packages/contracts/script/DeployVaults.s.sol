// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";

import { CredbullFixedYieldVaultFactory } from "@credbull/CredbullFixedYieldVaultFactory.sol";
import { CredbullUpsideVaultFactory } from "@credbull/CredbullUpsideVaultFactory.sol";
import { CredbullWhiteListProvider } from "@credbull/CredbullWhiteListProvider.sol";
import { Vault } from "@credbull/vault/Vault.sol";

import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";
import { SimpleToken } from "@test/test/token/SimpleToken.t.sol";
import { SimpleVault } from "@test/test/vault/SimpleVault.t.sol";

import { VaultsConfigured } from "./Configured.s.sol";
import { VaultsSupportConfigured } from "./Configured.s.sol";
import { DeployedContracts } from "./DeployedContracts.s.sol";

/// @notice The [Script] used to deploy the Credbull Vaults Distribution.
contract DeployVaults is Script, VaultsConfigured {
    /**
     * @notice The `forge script` invocation entrypoint, this deploys the Vaults Distribution Unit and, optionally,
     *  the Vaults Support Distribution Unit, if deployment is enabled.
     * @dev For command line invocation, the return values are ignored.
     *
     * @return fixedYieldVaultFactory The deployed [CredbullFixedYieldVaultFactory].
     * @return upsideVaultFactory The deployed [CredbullUpsideVaultFactory].
     * @return whiteListProvider The deployed [CredbullWhiteListProvider].
     */
    function run()
        external
        returns (CredbullFixedYieldVaultFactory, CredbullUpsideVaultFactory, CredbullWhiteListProvider)
    {
        new DeployVaultsSupport().run();

        return deploy(false);
    }

    /**
     * @dev Deploys the Vaults Distribution Unit, if the contracts are deployable.
     *
     * @param skipDeployCheck A [bool] flag determining whether to check if deployment is possible or not.
     *
     * @return fixedYieldVaultFactory The deployed [CredbullFixedYieldVaultFactory].
     * @return upsideVaultFactory The deployed [CredbullUpsideVaultFactory].
     * @return whiteListProvider The deployed [CredbullWhiteListProvider].
     */
    function deploy(bool skipDeployCheck)
        public
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
        if (skipDeployCheck || deployChecker.isDeployRequired("CredbullFixedYieldVaultFactory")) {
            fixedYieldVaultFactory = new CredbullFixedYieldVaultFactory(owner, operator, custodians);
        }
        if (skipDeployCheck || deployChecker.isDeployRequired("CredbullUpsideVaultFactory")) {
            upsideVaultFactory = new CredbullUpsideVaultFactory(owner, operator, custodians);
        }
        if (skipDeployCheck || deployChecker.isDeployRequired("CredbullWhiteListProvider")) {
            whiteListProvider = new CredbullWhiteListProvider(operator);
        }
        vm.stopBroadcast();

        return (fixedYieldVaultFactory, upsideVaultFactory, whiteListProvider);
    }
}

/// @notice The [Script] for deploying the Vaults Support Distribution Unit.
contract DeployVaultsSupport is Script, VaultsSupportConfigured {
    uint128 public constant MAXIMUM_SUPPLY = type(uint128).max;

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
            (cbl, usdc, vault) = deploy(false);
        }
        return (cbl, usdc, vault);
    }

    /**
     * @dev Deploys the Vaults Support Distribution Unit, if deployable.
     *
     * @param skipDeployCheck A [bool] flag determining whether to check if deployment is possible or not.
     *
     * @return cbl The deployed [SimpleToken] token representing the [$CBL].
     * @return usdc The deployed [SimpleUSDC] token representing [$USDC] (i.e. a stablecoin).
     * @return vault The deployed [SimpleVault].
     */
    function deploy(bool skipDeployCheck) public returns (SimpleToken cbl, SimpleUSDC usdc, SimpleVault vault) {
        DeployedContracts deployChecker = new DeployedContracts();

        vm.startBroadcast();
        if (skipDeployCheck || deployChecker.isDeployRequired("SimpleToken")) {
            cbl = new SimpleToken(MAXIMUM_SUPPLY);
        }
        if (skipDeployCheck || deployChecker.isDeployRequired("SimpleUSDC")) {
            usdc = new SimpleUSDC(MAXIMUM_SUPPLY);
        }
        if (skipDeployCheck || deployChecker.isDeployRequired("SimpleVault")) {
            vault = new SimpleVault(
                Vault.VaultParams({ asset: usdc, shareName: "Simple Vault", shareSymbol: "sVLT", custodian: custodian() })
            );
        }
        vm.stopBroadcast();

        return (cbl, usdc, vault);
    }
}
