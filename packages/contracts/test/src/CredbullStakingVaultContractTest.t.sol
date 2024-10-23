//SDPX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { HelperConfig } from "@script/HelperConfig.s.sol";
import { DeployStakingVaults } from "@script/DeployStakingVaults.s.sol";
import { CredbullFixedYieldVault } from "@credbull/CredbullFixedYieldVault.sol";
import { SimpleToken } from "@test/test/token/SimpleToken.t.sol";
import { NetworkConfig } from "@script/HelperConfig.s.sol";

contract CredbullStakingVaultContractTest is Test {
    CredbullFixedYieldVault private vault;
    HelperConfig private helperConfig;
    DeployStakingVaults private deployer;
    NetworkConfig private config;
    SimpleToken private cblToken;

    address private alice = makeAddr("alice");

    function setUp() public {
        deployer = new DeployStakingVaults();
        (, vault, helperConfig) = deployer.runTest();
        config = helperConfig.getNetworkConfig();

        cblToken = SimpleToken(address(config.cblToken));
        cblToken.mint(alice, 100000e18);
    }

    function test__StakingVaults() public {
        vm.prank(config.factoryParams.owner);
        vault.toggleWindowCheck();

        vm.startPrank(alice);
        cblToken.approve(address(vault), 1000e18);
        vault.deposit(1000e18, alice);
        vm.stopPrank();
    }
}
