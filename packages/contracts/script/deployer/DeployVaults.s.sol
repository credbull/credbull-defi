// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

import { CredbullFixedYieldVaultFactory } from "@credbull/CredbullFixedYieldVaultFactory.sol";
import { CredbullUpsideVaultFactory } from "@credbull/CredbullUpsideVaultFactory.sol";
import { CredbullWhiteListProvider } from "@credbull/CredbullWhiteListProvider.sol";
import { Vault } from "@credbull/vault/Vault.sol";

import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";
import { SimpleToken } from "@test/test/token/SimpleToken.t.sol";
import { SimpleVault } from "@test/test/vault/SimpleVault.t.sol";

import { ConfiguredToDeployVaults } from "./Configured.s.sol";
import { ConfiguredToDeployVaultsSupport } from "./Configured.s.sol";

/// @notice The [Script] used to deploy the Credbull Vaults Distribution.
contract DeployVaults is ConfiguredToDeployVaults {
    /**
     * @notice The `forge script` invocation entrypoint, this deploys the Credbull Vaults Distribution.
     * @dev For command line invocation, the return values are ignored, but are included for test usages.
     *
     * @return fixedYieldVaultFactory The deployed [CredbullFixedYieldVaultFactory].
     * @return upsideVaultFactory The deployed [CredbullUpsideVaultFactory].
     * @return whiteListProvider The deployed [CredbullWhiteListProvider].
     */
    function run()
        external
        returns (CredbullFixedYieldVaultFactory, CredbullUpsideVaultFactory, CredbullWhiteListProvider)
    {
        DeployVaultsSupport deployer = new DeployVaultsSupport();
        if (deployer.isDeploySupport()) deployer.run();

        return deploy();
    }

    function deploy()
        private
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

        vm.startBroadcast();
        fixedYieldVaultFactory = new CredbullFixedYieldVaultFactory(owner, operator, custodians);
        upsideVaultFactory = new CredbullUpsideVaultFactory(owner, operator, custodians);
        whiteListProvider = new CredbullWhiteListProvider(operator);
        vm.stopBroadcast();

        return (fixedYieldVaultFactory, upsideVaultFactory, whiteListProvider);
    }
}

/**
 * @notice A deployment utility contract for deploying support contracts under controlled circumstances.
 */
contract DeployVaultsSupport is ConfiguredToDeployVaultsSupport {
    uint128 public constant MAXIMUM_SUPPLY = type(uint128).max;

    /**
     * @notice The `forge script` invocation entrypoint, this deploys the Credbull Vaults Support Distribution,
     *  a [$CBL] representative token, a [$USDC] representative stablecoin token and an example [Vault].
     * @dev For command line invocation, the return values are ignored, but included for test usages.
     *
     * @return cbl The deployed [IERC20] token (a [SimpleToken]) representing the [$CBL].
     * @return usdc The deployed [IERC20] token (a [SimpleUSDC]) representing [$USDC] (i.e. a stablecoin).
     * @return vault The deployed [Vault] (a [SimpleVault]]).
     */
    function run() external returns (IERC20 cbl, IERC20 usdc, Vault vault) {
        address custodian = custodian();

        vm.startBroadcast();
        cbl = new SimpleToken(MAXIMUM_SUPPLY);
        usdc = new SimpleUSDC(MAXIMUM_SUPPLY);
        vault = new SimpleVault(
            Vault.VaultParams({ asset: usdc, shareName: "Simple Vault", shareSymbol: "sVLT", custodian: custodian })
        );
        vm.stopBroadcast();

        return (cbl, usdc, vault);
    }
}
