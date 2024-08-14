// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";

import { DeployVaultsSupport } from "@script/DeployVaultsSupport.s.sol";

import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";
import { SimpleToken } from "@test/test/token/SimpleToken.t.sol";
import { SimpleVault } from "@test/test/vault/SimpleVault.t.sol";

contract DeployVaultsSupportTest is Test {
    function test_DeployVaultsSupport_RunDeploys() public {
        DeployVaultsSupport deployer = new DeployVaultsSupport().skipDeployCheck();
        (SimpleToken cbl, SimpleUSDC usdc, SimpleVault vault) = deployer.run();

        assertNotEq(address(0), address(cbl));
        assertNotEq(address(0), address(usdc));
        assertNotEq(address(0), address(vault));
    }

    function test_DeployVaultsSupport_RunWithSkipDeploys() public {
        DeployVaultsSupport deployer = new DeployVaultsSupport().skipDeployCheck();
        (SimpleToken cbl, SimpleUSDC usdc, SimpleVault vault) = deployer.run();

        assertNotEq(address(0), address(cbl));
        assertNotEq(address(0), address(usdc));
        assertNotEq(address(0), address(vault));
    }

    function test_DeployVaultsSupport_WhenDisabledDoesNotDeploy() public {
        DeployVaultsSupport deployer = new DisabledDeployVaultSupport();
        (SimpleToken cbl, SimpleUSDC usdc, SimpleVault vault) = deployer.run();

        assertEq(address(0), address(cbl));
        assertEq(address(0), address(usdc));
        assertEq(address(0), address(vault));
    }
}

contract DisabledDeployVaultSupport is DeployVaultsSupport {
    string private constant CONFIG = "[deployment.vaults_support]\n" "deploy = false\n";

    function loadConfiguration(string memory) internal pure override returns (string memory) {
        return CONFIG;
    }
}
