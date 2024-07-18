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

    function run() external returns (IERC20 cbl, IERC20 usdc, Vault vault) {
        if (deploySupport()) {
            address custodian = custodian();

            vm.startBroadcast();
            // NOTE (JL,2024-07-18): Use actual CBL?
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
