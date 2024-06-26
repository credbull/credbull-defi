//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

import { Test } from "forge-std/Test.sol";

import { HelperConfig, NetworkConfig } from "@script/HelperConfig.s.sol";
import { DeployVaultFactory } from "@script/DeployVaultFactory.s.sol";

import { CredbullFixedYieldVaultFactory } from "@src/CredbullFixedYieldVaultFactory.sol";
import { CredbullFixedYieldVault } from "@src/CredbullFixedYieldVault.sol";
import { CredbullKYCProvider } from "@src/CredbullKYCProvider.sol";
import { VaultFactory } from "@src/factory/VaultFactory.sol";

import { ParametersFactory } from "@test/test/vault/ParametersFactory.t.sol";

contract CredbullFixedYieldVaultFactoryTest is Test {
    CredbullFixedYieldVaultFactory private factory;
    DeployVaultFactory private deployer;
    HelperConfig private helperConfig;
    CredbullKYCProvider private kycProvider;
    NetworkConfig private config;
    CredbullFixedYieldVault.FixedYieldVaultParameters private params;

    string private OPTIONS = "{}";

    function setUp() public {
        deployer = new DeployVaultFactory();
        (factory,, kycProvider, helperConfig) = deployer.runTest();
        config = helperConfig.getNetworkConfig();
        params = new ParametersFactory(config).createFixedYieldVaultParameters();

        params.whitelistPlugIn.kycProvider = address(kycProvider);
    }

    function test__CreateVaultFromFactory() public {
        vm.prank(config.factoryParams.owner);
        factory.allowCustodian(params.maturityVault.vault.custodian);

        vm.prank(config.factoryParams.operator);
        CredbullFixedYieldVault vault = CredbullFixedYieldVault(payable(factory.createVault(params, OPTIONS)));

        assertEq(vault.asset(), address(params.maturityVault.vault.asset));
        assertEq(vault.name(), params.maturityVault.vault.shareName);
        assertEq(vault.symbol(), params.maturityVault.vault.shareSymbol);
        assertEq(address(vault.kycProvider()), params.whitelistPlugIn.kycProvider);
        assertEq(vault.CUSTODIAN(), params.maturityVault.vault.custodian);
    }

    function test__ShouldRevertCreateVaultOnUnAuthorizedUser() public {
        vm.prank(config.factoryParams.owner);
        vm.expectRevert();
        factory.createVault(params, OPTIONS);
    }

    function test__ShouldAllowAdminToChangeOperator() public {
        address newOperator = makeAddr("new_operator");

        vm.startPrank(config.factoryParams.owner);
        factory.allowCustodian(params.maturityVault.vault.custodian);
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
        factory.createVault(params, OPTIONS);
        vm.stopPrank();

        vm.prank(newOperator);
        factory.createVault(params, OPTIONS);
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
        vm.prank(config.factoryParams.owner);
        factory.allowCustodian(params.maturityVault.vault.custodian);

        params.maturityVault.vault.custodian = makeAddr("randomCustodian");

        vm.prank(config.factoryParams.operator);
        vm.expectRevert(VaultFactory.CredbullVaultFactory__CustodianNotAllowed.selector);
        factory.createVault(params, OPTIONS);
    }

    function test__ShouldAllowAdminToAddCustodians() public {
        vm.prank(config.factoryParams.owner);
        factory.allowCustodian(params.maturityVault.vault.custodian);

        assertTrue(factory.isCustodianAllowed(params.maturityVault.vault.custodian));
    }

    function test__ShoulRemoveCustodianIfExist() public {
        vm.startPrank(config.factoryParams.owner);
        factory.allowCustodian(params.maturityVault.vault.custodian);
        assertTrue(factory.isCustodianAllowed(params.maturityVault.vault.custodian));

        factory.removeCustodian(params.maturityVault.vault.custodian);
        assertTrue(!factory.isCustodianAllowed(params.maturityVault.vault.custodian));
        vm.stopPrank();
    }

    function test__ShouldRevertAllowAdmingIfNotOwner() public {
        vm.prank(makeAddr("random_addr"));
        vm.expectRevert();
        factory.allowCustodian(params.maturityVault.vault.custodian);
    }

    function createVault() internal returns (CredbullFixedYieldVault vault) {
        vm.prank(config.factoryParams.owner);
        factory.allowCustodian(params.maturityVault.vault.custodian);

        vm.prank(config.factoryParams.operator);
        vault = CredbullFixedYieldVault(payable(factory.createVault(params, OPTIONS)));
    }
}
