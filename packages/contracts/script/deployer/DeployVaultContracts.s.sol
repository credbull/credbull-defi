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

// NOTE (JL,2024-07-17): Naming is hard. I would like to call this 'Deploy Vault Distribution'. Somehow capture the
//  'unit' of what this deployment is.
abstract contract DeployVaultContracts is VaultFactoryConfigured {
    using stdToml for string;

    uint128 public constant MAXIMUM_SUPPLY = type(uint128).max;

    function deployTo(string memory network)
        internal
        returns (CredbullFixedYieldVaultFactory, CredbullUpsideVaultFactory, CredbullWhiteListProvider)
    {
        return deployVaultContracts(network);
    }

    function deployVaultContracts(string memory network)
        internal
        virtual
        returns (CredbullFixedYieldVaultFactory, CredbullUpsideVaultFactory, CredbullWhiteListProvider)
    {
        address owner = vaultFactoryOwner(network);
        address operator = vaultFactoryOperator(network);
        address[] memory custodians = new address[](1);
        custodians[0] = vaultFactoryCustodian(network);

        vm.startBroadcast();
        CredbullFixedYieldVaultFactory fyvf = new CredbullFixedYieldVaultFactory(owner, operator, custodians);
        CredbullUpsideVaultFactory uvf = new CredbullUpsideVaultFactory(owner, operator, custodians);
        CredbullWhiteListProvider wlp = new CredbullWhiteListProvider(operator);
        vm.stopBroadcast();

        return (fyvf, uvf, wlp);
    }
}

contract Arbitrum is DeployVaultContracts {
    function run() external {
        deployTo("Arbitrum");
    }

    // NOTE (JL,2024-07-16): Arbitrum specific steps here, if needed.
}

contract BaseSepolia is DeployVaultContracts {
    function run() external {
        deployTo("BaseSepolia");
    }
}

contract Local is DeployVaultContracts {
    function run() external {
        deployTo("Local");
    }
}

contract Test is DeployVaultContracts {
    function runTest()
        external
        returns (CredbullFixedYieldVaultFactory, CredbullUpsideVaultFactory, CredbullWhiteListProvider)
    {
        return deployTo("Test");
    }
}
