// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

import { Vault } from "@credbull/vault/Vault.sol";

import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";
import { SimpleToken } from "@test/test/token/SimpleToken.t.sol";
import { SimpleVault } from "@test/test/vault/SimpleVault.t.sol";

import { ConfiguredToDeployVaultsSupport } from "./Configured.s.sol";

/// @notice Deploys support contracts (e.g. an example Vault, a stablecoin) for the Vaults Distribution.
contract DeployVaultsSupport is ConfiguredToDeployVaultsSupport {
    uint128 public constant MAXIMUM_SUPPLY = type(uint128).max;

    /**
     * @notice The `forge script` invocation entrypoint, this conditionally deploys a [$CBL] representative token, a
     *  [$USDC] representative stablecoin token and an example [Vault].
     * @dev Deployment is conditional on it being enabled. The return values are ignored, but included for test
     *  usages.
     *
     * @return cbl The deployed [IERC20] token (a [SimpleToken]) representing the [$CBL].
     * @return usdc The deployed [IERC20] token (a [SimpleUSDC]) representing [$USDC] (i.e. a stablecoin).
     * @return vault The deployed [Vault] (a [SimpleVault]]).
     */
    function run() external returns (IERC20 cbl, IERC20 usdc, Vault vault) {
        if (deploySupport()) {
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

        return (cbl, usdc, vault);
    }
}
