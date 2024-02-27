//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { CredbullFixedYieldVaultFactory } from "../../src/factories/CredbullFixedYieldVaultFactory.sol";
import { DeployVaultFactory } from "../../script/DeployVaultFactory.s.sol";
import { HelperConfig, NetworkConfig } from "../../script/HelperConfig.s.sol";
import { ICredbull } from "../../src/interface/ICredbull.sol";
import { CredbullFixedYieldVault } from "../../src/CredbullFixedYieldVault.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { CredbullVaultFactory } from "../../src/factories/CredbullVaultFactory.sol";

contract CredbullFixedYieldVaultFactoryTest is Test {
    CredbullFixedYieldVaultFactory private factory;
    DeployVaultFactory private deployer;
    HelperConfig private helperConfig;

    string private OPTIONS = "{}";

    function setUp() public {
        deployer = new DeployVaultFactory();
        (factory,, helperConfig) = deployer.runTest();
    }

    function test__CreateVaultFromFactory() public {
        NetworkConfig memory config = helperConfig.getNetworkConfig();
        ICredbull.VaultParams memory params = config.vaultParams;

        vm.prank(config.factoryParams.owner);
        factory.allowCustodian(params.custodian);

        vm.prank(config.factoryParams.operator);
        CredbullFixedYieldVault vault = CredbullFixedYieldVault(factory.createVault(params, OPTIONS));

        assertEq(vault.asset(), address(params.asset));
        assertEq(vault.name(), params.shareName);
        assertEq(vault.symbol(), params.shareSymbol);
        assertEq(address(vault.kycProvider()), params.kycProvider);
        assertEq(vault.CUSTODIAN(), params.custodian);
    }

    function test__ShouldRevertCreateVaultOnUnAuthorizedUser() public {
        NetworkConfig memory config = helperConfig.getNetworkConfig();

        vm.prank(config.factoryParams.owner);
        vm.expectRevert();
        factory.createVault(config.vaultParams, OPTIONS);
    }

    function test__ShouldAllowAdminToChangeOperator() public {
        NetworkConfig memory config = helperConfig.getNetworkConfig();
        address newOperator = makeAddr("new_operator");

        vm.startPrank(config.factoryParams.owner);
        factory.allowCustodian(config.vaultParams.custodian);
        factory.revokeRole(factory.OPERATOR_ROLE(), config.factoryParams.operator);
        factory.grantRole(factory.OPERATOR_ROLE(), newOperator);
        vm.stopPrank();

        vm.startPrank(config.factoryParams.operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                config.factoryParams.operator,
                factory.OPERATOR_ROLE()
            )
        );
        factory.createVault(config.vaultParams, OPTIONS);
        vm.stopPrank();

        vm.prank(newOperator);
        factory.createVault(config.vaultParams, OPTIONS);
    }

    function test__VaultCountShouldReturnCorrectVault() public {
        createVault();
        assertEq(factory.getTotalVaultCount(), 1);
    }

    function test__ShouldReturnVaultAtIndex() public {
        CredbullFixedYieldVault vault = createVault();
        assertEq(factory.getVaultAtIndex(0), address(vault));
    }

    function test__ShouldReturnVaultExistStatus() public {
        CredbullFixedYieldVault vault = createVault();
        assertEq(factory.isVaultExist(address(vault)), true);
    }

    function test__ShouldRevertOnNotAllowedCustodians() public {
        NetworkConfig memory config = helperConfig.getNetworkConfig();
        ICredbull.VaultParams memory params = config.vaultParams;

        vm.prank(config.factoryParams.owner);
        factory.allowCustodian(config.vaultParams.custodian);

        params.custodian = makeAddr("randomCustodian");

        vm.prank(config.factoryParams.operator);
        vm.expectRevert(CredbullVaultFactory.CredbullVaultFactory__CustodianNotAllowed.selector);
        factory.createVault(params, OPTIONS);
    }

    function test__ShouldAllowAdminToAddCustodians() public {
        NetworkConfig memory config = helperConfig.getNetworkConfig();

        vm.prank(config.factoryParams.owner);
        factory.allowCustodian(config.vaultParams.custodian);

        assertTrue(factory.isCustodianAllowed(config.vaultParams.custodian));
    }

    function test__ShoulRemoveCustodianIfExist() public {
        NetworkConfig memory config = helperConfig.getNetworkConfig();

        vm.startPrank(config.factoryParams.owner);
        factory.allowCustodian(config.vaultParams.custodian);
        assertTrue(factory.isCustodianAllowed(config.vaultParams.custodian));

        factory.removeCustodian(config.vaultParams.custodian);
        assertTrue(!factory.isCustodianAllowed(config.vaultParams.custodian));
        vm.stopPrank();
    }

    function test__ShouldRevertAllowAdmingIfNotOwner() public {
        NetworkConfig memory config = helperConfig.getNetworkConfig();

        vm.prank(makeAddr("random_addr"));
        vm.expectRevert();
        factory.allowCustodian(config.vaultParams.custodian);
    }

    function createVault() internal returns (CredbullFixedYieldVault vault) {
        NetworkConfig memory config = helperConfig.getNetworkConfig();
        ICredbull.VaultParams memory params = config.vaultParams;

        vm.prank(config.factoryParams.owner);
        factory.allowCustodian(config.vaultParams.custodian);

        vm.prank(config.factoryParams.operator);
        vault = CredbullFixedYieldVault(factory.createVault(params, OPTIONS));
    }
}
