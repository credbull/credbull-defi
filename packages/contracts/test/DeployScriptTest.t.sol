// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test } from "forge-std/Test.sol";

import { DeployVaultFactory } from "../script/DeployVaultFactory.s.sol";
import { HelperConfig, NetworkConfig } from "../script/HelperConfig.s.sol";

import { CredbullFixedYieldVault } from "../src/CredbullFixedYieldVault.sol";
import { CredbullVaultFactory } from "../src/factories/CredbullVaultFactory.sol";

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

contract DeployScriptTest is Test {
    DeployVaultFactory private deployScript;

    CredbullVaultFactory factory;
    CredbullVaultFactory upsideFactory;

    CredbullFixedYieldVault private usdc10APYVault;

    HelperConfig private helperConfig;
    NetworkConfig private networkConfig;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    function setUp() public {
        deployScript = new DeployVaultFactory();

        (factory, upsideFactory,, helperConfig) = deployScript.runTest();
        (helperConfig, usdc10APYVault) = deployScript.deployVault();

        networkConfig = helperConfig.getNetworkConfig();
    }

    function test__DeployScriptTest_DeployVaultFactories() public view {
        assertNotEq(address(0), address(factory), "zeroAddress - check CredbullFixedYieldVaultFactory deploy");
        assertVaultFactoryRoles(factory);

        assertNotEq(address(0), address(upsideFactory), "zeroAddress - check CredbullUpsideVaultFactory deploy");
        assertVaultFactoryRoles(upsideFactory);
    }

    function test__DeployScriptTest_DeployVault() public view {
        assertNotEq(address(0), address(usdc10APYVault), "zeroAddress - check CredbullVault deploy");

        assertVaultRoles(usdc10APYVault);
    }

    function assertVaultFactoryRoles(CredbullVaultFactory vaultFactory) internal view {
        assertHasRole(
            vaultFactory, DEFAULT_ADMIN_ROLE, networkConfig.factoryParams.owner, "vaultFactory owner missing owner role"
        );
        assertHasRole(
            vaultFactory,
            OPERATOR_ROLE,
            networkConfig.factoryParams.operator,
            "vaultFactory operatorRole missing operator role"
        ); // this is the correct impl

        // ----- custodian allowed
        assertTrue(
            vaultFactory.isCustodianAllowed(networkConfig.factoryParams.custodian), "custodian not set on vaultFactory"
        );
    }

    function assertVaultRoles(CredbullFixedYieldVault _credbullVault) internal view {
        assertHasRole(
            _credbullVault, DEFAULT_ADMIN_ROLE, networkConfig.factoryParams.owner, "vault owner missing owner role"
        );
        assertHasRole(
            _credbullVault, OPERATOR_ROLE, networkConfig.factoryParams.operator, "vault operator missing operator role"
        );
        assertEq(
            address(_credbullVault.CUSTODIAN()), networkConfig.factoryParams.custodian, "custodian not set on vault"
        );
    }

    function assertHasRole(AccessControl accessControl, bytes32 role, address account, string memory errMsg)
        internal
        view
    {
        assertTrue(accessControl.hasRole(role, account), errMsg);
    }
}
