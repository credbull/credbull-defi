// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { CredbullFixedYieldVaultFactory } from "@credbull/CredbullFixedYieldVaultFactory.sol";
import { CredbullUpsideVaultFactory } from "@credbull/CredbullUpsideVaultFactory.sol";
import { CredbullWhiteListProvider } from "@credbull/CredbullWhiteListProvider.sol";

import { DeployVaultContracts } from "@script/deployer/DeployVaultContracts.s.sol";

contract TestDeployer is DeployVaultContracts {
    function runTest()
        external
        returns (CredbullFixedYieldVaultFactory, CredbullUpsideVaultFactory, CredbullWhiteListProvider)
    {
        return deployTo("Test");
    }
}
