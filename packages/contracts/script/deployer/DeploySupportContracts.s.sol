// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";
import { stdToml } from "forge-std/StdToml.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

import { CredbullFixedYieldVaultFactory } from "@credbull/CredbullFixedYieldVaultFactory.sol";
import { CredbullUpsideVaultFactory } from "@credbull/CredbullUpsideVaultFactory.sol";
import { CredbullWhiteListProvider } from "@credbull/CredbullWhiteListProvider.sol";
import { Vault } from "@credbull/vault/Vault.sol";

import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";
import { SimpleToken } from "@test/test/token/SimpleToken.t.sol";
import { SimpleVault } from "@test/test/vault/SimpleVault.t.sol";

import { VaultFactoryConfigured } from "./Configured.s.sol";

abstract contract DeploySupportContracts is VaultFactoryConfigured {
    using stdToml for string;

    uint128 public constant MAXIMUM_SUPPLY = type(uint128).max;

    function deployTo(string memory network) internal returns (IERC20, IERC20, Vault) {
        return deploySupportContracts(network);
    }

    function deploySupportContracts(string memory network)
        internal
        virtual
        returns (IERC20 cbl, IERC20 usdc, Vault vault)
    {
        if (doDeploySupportContracts(network)) {
            address custodian = vaultFactoryCustodian(network);

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

contract Arbitrum is DeploySupportContracts {
    function run() external {
        deployTo("Arbitrum");
    }

    // NOTE (JL,2024-07-16): Arbitrum specific steps here.
}

contract BaseSepolia is DeploySupportContracts {
    function run() external {
        deployTo("BaseSepolia");
    }
}

contract Local is DeploySupportContracts {
    function run() external {
        deployTo("Local");
    }
}

contract Test is DeploySupportContracts {
    function run() external {
        deployTo("Test");
    }
}
