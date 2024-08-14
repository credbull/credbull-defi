// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";

import { CredbullFixedYieldVaultFactory } from "@credbull/CredbullFixedYieldVaultFactory.sol";
import { CredbullUpsideVaultFactory } from "@credbull/CredbullUpsideVaultFactory.sol";
import { CredbullWhiteListProvider } from "@credbull/CredbullWhiteListProvider.sol";

import { DeployVaults } from "@script/DeployVaults.s.sol";

contract DeployVaultsTest is Test {
    function test_DeployVaults_RunDeploys() public {
        DeployVaults deployer = new DeployVaults().skipDeployCheck();
        (CredbullFixedYieldVaultFactory fyvf, CredbullUpsideVaultFactory uvf, CredbullWhiteListProvider wlp) =
            deployer.run();

        assertNotEq(address(0), address(fyvf));
        assertNotEq(address(0), address(uvf));
        assertNotEq(address(0), address(wlp));
    }

    function test_DeployVaults_RunSkipDeploys() public {
        DeployVaults deployer = new DeployVaults().skipDeployCheck();
        (CredbullFixedYieldVaultFactory fyvf, CredbullUpsideVaultFactory uvf, CredbullWhiteListProvider wlp) =
            deployer.run();

        assertNotEq(address(0), address(fyvf));
        assertNotEq(address(0), address(uvf));
        assertNotEq(address(0), address(wlp));
    }
}
