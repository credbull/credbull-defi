//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";

import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { DeployVaults } from "@script/DeployVaults.s.sol";
import { DeployVaultsSupport } from "@script/DeployVaultsSupport.s.sol";
import { VaultsSupportConfig } from "@script/TomlConfig.s.sol";

import { CredbullFixedYieldVaultFactory } from "@credbull/CredbullFixedYieldVaultFactory.sol";
import { CredbullFixedYieldVault } from "@credbull/CredbullFixedYieldVault.sol";
import { CredbullWhiteListProvider } from "@credbull/CredbullWhiteListProvider.sol";
import { VaultFactory } from "@credbull/factory/VaultFactory.sol";

import { ParamsFactory } from "@test/test/vault/utils/ParamsFactory.t.sol";

contract CredbullFixedYieldVaultFactoryTest is Test, VaultsSupportConfig {
    DeployVaults private deployer;
    DeployVaultsSupport private supportDeployer;

    CredbullFixedYieldVaultFactory private factory;
    CredbullWhiteListProvider private whiteListProvider;
    CredbullFixedYieldVault.FixedYieldVaultParams private params;

    string private OPTIONS = "{}";

    function setUp() public {
        deployer = new DeployVaults().skipDeployCheck();
        supportDeployer = new DeployVaultsSupport().skipDeployCheck();

        (factory,, whiteListProvider) = deployer.run();
        (ERC20 cbl, ERC20 usdc,) = supportDeployer.run();

        params = new ParamsFactory(usdc, cbl).createFixedYieldVaultParams();
        params.whiteListPlugin.whiteListProvider = address(whiteListProvider);
    }

    function test__ShouldRevertOnInvalidParams() public {
        vm.prank(config.factoryParams.owner);
        vm.expectRevert(VaultFactory.CredbullVaultFactory__InvalidOwnerAddress.selector);
        new CredbullFixedYieldVaultFactory(address(0), config.factoryParams.operator, new address[](0));

        vm.expectRevert(VaultFactory.CredbullVaultFactory__InvalidOperatorAddress.selector);
        new CredbullFixedYieldVaultFactory(config.factoryParams.owner, address(0), new address[](0));

        vm.expectRevert(VaultFactory.CredbullVaultFactory__InvalidCustodianAddress.selector);
        new CredbullFixedYieldVaultFactory(config.factoryParams.owner, config.factoryParams.operator, new address[](1));
    }

    function test__ShouldSuccefullyCreateFactoryFixedYield() public {
        address[] memory custodians = new address[](1);
        custodians[0] = custodian();
        CredbullFixedYieldVaultFactory vaultFactory =
            new CredbullFixedYieldVaultFactory(owner(), operator(), custodians);
        vaultFactory.hasRole(vaultFactory.OPERATOR_ROLE(), operator());
    }

    function test__CreateVaultFromFactory() public {
        vm.prank(owner());
        factory.allowCustodian(params.maturityVault.vault.custodian);

        vm.prank(operator());
        CredbullFixedYieldVault vault = CredbullFixedYieldVault(payable(factory.createVault(params, OPTIONS)));

        assertEq(vault.asset(), address(params.maturityVault.vault.asset));
        assertEq(vault.name(), params.maturityVault.vault.shareName);
        assertEq(vault.symbol(), params.maturityVault.vault.shareSymbol);
        assertEq(address(vault.WHITELIST_PROVIDER()), params.whiteListPlugin.whiteListProvider);
        assertEq(vault.CUSTODIAN(), params.maturityVault.vault.custodian);
    }

    function test__ShouldRevertCreateVaultOnUnAuthorizedUser() public {
        vm.prank(owner());
        vm.expectRevert();
        factory.createVault(params, OPTIONS);
    }

    function test__ShouldAllowAdminToChangeOperator() public {
        address newOperator = makeAddr("new_operator");

        vm.startPrank(owner());
        factory.allowCustodian(params.maturityVault.vault.custodian);
        factory.revokeRole(factory.OPERATOR_ROLE(), operator());
        factory.grantRole(factory.OPERATOR_ROLE(), newOperator);
        vm.stopPrank();

        vm.startPrank(operator());
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, operator(), factory.OPERATOR_ROLE()
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
        vm.prank(owner());
        factory.allowCustodian(params.maturityVault.vault.custodian);

        params.maturityVault.vault.custodian = makeAddr("randomCustodian");

        vm.prank(operator());
        vm.expectRevert(VaultFactory.CredbullVaultFactory__CustodianNotAllowed.selector);
        factory.createVault(params, OPTIONS);
    }

    function test__ShouldAllowAdminToAddCustodians() public {
        vm.prank(owner());
        vm.expectEmit();
        emit VaultFactory.CustodianAllowed(params.maturityVault.vault.custodian);
        factory.allowCustodian(params.maturityVault.vault.custodian);

        assertTrue(factory.isCustodianAllowed(params.maturityVault.vault.custodian));
    }

    function test__ShoulRemoveCustodianIfExist() public {
        vm.startPrank(owner());
        factory.allowCustodian(params.maturityVault.vault.custodian);
        assertTrue(factory.isCustodianAllowed(params.maturityVault.vault.custodian));

        vm.expectEmit();
        emit VaultFactory.CustodianRemoved(params.maturityVault.vault.custodian);
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
        vm.prank(owner());
        factory.allowCustodian(params.maturityVault.vault.custodian);

        vm.prank(operator());
        vault = CredbullFixedYieldVault(payable(factory.createVault(params, OPTIONS)));
    }
}
