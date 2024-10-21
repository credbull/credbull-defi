//SDPX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { HelperConfig } from "@script/HelperConfig.s.sol";
import { DeployStakingVaults } from "@script/DeployStakingVaults.s.sol";
import { CredbullFixedYieldVault } from "@credbull/CredbullFixedYieldVault.sol";

contract CredbullStakingVaultContractTest is Test {
    CredbullFixedYieldVault[] private vaults;
    HelperConfig private helperConfig;
    DeployStakingVaults private deployer;

    function setUp() public {
        deployer = new DeployStakingVaults();
        (, vaults, helperConfig) = deployer.runTest();
    }
}
