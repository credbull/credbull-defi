//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { CredbullVaultFactory } from "../../src/factories/CredbullVaultFactory.sol";
import { DeployVaultFactory } from "../../script/DeployVaultFactory.s.sol";
import { HelperConfig, NetworkConfig } from "../../script/HelperConfig.s.sol";
import { ICredbull } from "../../src/interface/ICredbull.sol";
import { CredbullFixedYieldVault } from "../../src/CredbullFixedYieldVault.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

contract CredbullVaultFactoryTest is Test {
    CredbullVaultFactory private factory;
    DeployVaultFactory private deployer;
    HelperConfig private helperConfig;

    string private constant OPTIONS = "{}";

    function setUp() public {
        deployer = new DeployVaultFactory();
        (factory, helperConfig) = deployer.runTest();
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
        assertEq(vault.custodian(), params.custodian);
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

    function createVault() internal returns (CredbullFixedYieldVault vault) {
        NetworkConfig memory config = helperConfig.getNetworkConfig();
        ICredbull.VaultParams memory params = config.vaultParams;

        vm.prank(config.factoryParams.owner);
        factory.allowCustodian(config.vaultParams.custodian);

        vm.prank(config.factoryParams.operator);
        vault = CredbullFixedYieldVault(factory.createVault(params, OPTIONS));
    }
}
