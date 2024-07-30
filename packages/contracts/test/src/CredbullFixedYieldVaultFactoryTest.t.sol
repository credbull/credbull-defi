//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

import { Test } from "forge-std/Test.sol";

import { HelperConfig, NetworkConfig } from "@script/HelperConfig.s.sol";
import { DeployVaultFactory } from "@script/DeployVaultFactory.s.sol";

import { CredbullFixedYieldVaultFactory } from "@credbull/CredbullFixedYieldVaultFactory.sol";
import { CredbullFixedYieldVault } from "@credbull/CredbullFixedYieldVault.sol";
import { CredbullWhiteListProvider } from "@credbull/CredbullWhiteListProvider.sol";
import { VaultFactory } from "@credbull/factory/VaultFactory.sol";

import { ParamsFactory } from "@test/test/vault/utils/ParamsFactory.t.sol";

contract CredbullFixedYieldVaultFactoryTest is Test {
    CredbullFixedYieldVaultFactory private factory;
    DeployVaultFactory private deployer;
    HelperConfig private helperConfig;
    CredbullWhiteListProvider private whiteListProvider;
    NetworkConfig private config;
    CredbullFixedYieldVault.FixedYieldVaultParams private params;

    string private OPTIONS = "{}";

    function setUp() public {
        deployer = new DeployVaultFactory();
        (factory,, whiteListProvider, helperConfig) = deployer.runTest();
        config = helperConfig.getNetworkConfig();
        params = new ParamsFactory(config).createFixedYieldVaultParams();

        params.whiteListPlugin.whiteListProvider = address(whiteListProvider);
    }

    function test__ShouldRevertOnInvalidParams() public {
        vm.prank(config.factoryParams.owner);
        vm.expectRevert(VaultFactory.CredbullVaultFactory__InvalidOwnerAddress.selector);
        new CredbullFixedYieldVaultFactory(address(0), config.factoryParams.operator, new address[](0));

        vm.expectRevert(VaultFactory.CredbullVaultFactory__InvalidOperatorAddress.selector);
        new CredbullFixedYieldVaultFactory(config.factoryParams.owner, address(0), new address[](0));
    }

    function test__ShouldSuccefullyCreateFactoryFixedYield() public {
        address[] memory custodians = new address[](1);
        custodians[0] = config.factoryParams.custodian;
        CredbullFixedYieldVaultFactory vaultFactory =
            new CredbullFixedYieldVaultFactory(config.factoryParams.owner, config.factoryParams.operator, custodians);
        vaultFactory.hasRole(vaultFactory.OPERATOR_ROLE(), config.factoryParams.operator);
    }

    function test__CreateVaultFromFactory() public {
        vm.prank(config.factoryParams.owner);
        factory.allowCustodian(params.maturityVault.vault.custodian);

        vm.prank(config.factoryParams.operator);
        CredbullFixedYieldVault vault = CredbullFixedYieldVault(payable(factory.createVault(params, OPTIONS)));

        assertEq(vault.asset(), address(params.maturityVault.vault.asset));
        assertEq(vault.name(), params.maturityVault.vault.shareName);
        assertEq(vault.symbol(), params.maturityVault.vault.shareSymbol);
        assertEq(address(vault.WHITELIST_PROVIDER()), params.whiteListPlugin.whiteListProvider);
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

    function test__ShouldRevertOnInvalidCustodian() public {
        vm.startPrank(config.factoryParams.owner);
        factory.allowCustodian(params.maturityVault.vault.custodian);

        vm.expectRevert(VaultFactory.CredbullVaultFactory__InvalidCustodianAddress.selector);
        factory.allowCustodian(address(0));
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
