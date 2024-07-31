// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";

import { DeployVaultsSupport } from "@script/DeployVaults.s.sol";

import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";
import { SimpleToken } from "@test/test/token/SimpleToken.t.sol";
import { SimpleVault } from "@test/test/vault/SimpleVault.t.sol";

contract DeployVaultsTest is DeployVaultsSupport, Test {
    function test_DeployVaultsSupport_RunDeploys() public {
        (SimpleToken cbl, SimpleUSDC usdc, SimpleVault vault) = this.run();

        assertNotEq(address(0), address(cbl));
        assertNotEq(address(0), address(usdc));
        assertNotEq(address(0), address(vault));
    }

    function test_DeployVaultsSupport_DeploySkipDeploys() public {
        (SimpleToken cbl, SimpleUSDC usdc, SimpleVault vault) = deploy(true);

        assertNotEq(address(0), address(cbl));
        assertNotEq(address(0), address(usdc));
        assertNotEq(address(0), address(vault));
    }

    function test_DeployVaults_DeployNoSkipDeploys() public {
        (SimpleToken cbl, SimpleUSDC usdc, SimpleVault vault) = deploy(false);

        assertNotEq(address(0), address(cbl));
        assertNotEq(address(0), address(usdc));
        assertNotEq(address(0), address(vault));
    }
}
