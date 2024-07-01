//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { HelperVaultTest } from "../base/HelperVaultTest.t.sol";
import { CredbullFixedYieldVaultFactory } from "../../src/factories/CredbullFixedYieldVaultFactory.sol";
import { DeployVaultFactory } from "../../script/DeployVaultFactory.s.sol";
import { HelperConfig, NetworkConfig } from "../../script/HelperConfig.s.sol";
import { CredbullFixedYieldVault } from "../../src/CredbullFixedYieldVault.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { CredbullVaultFactory } from "../../src/factories/CredbullVaultFactory.sol";
import { CredbullKYCProvider } from "../../src/CredbullKYCProvider.sol";

contract CredbullFixedYieldVaultFactoryTest is Test {
    CredbullFixedYieldVaultFactory private factory;
    DeployVaultFactory private deployer;
    HelperConfig private helperConfig;
    CredbullKYCProvider private kycProvider;
    NetworkConfig private config;
    CredbullFixedYieldVault.FixedYieldVaultParams private params;

    string private OPTIONS = "{}";

    function setUp() public {
        deployer = new DeployVaultFactory();
        (factory,, kycProvider, helperConfig) = deployer.runTest();
        config = helperConfig.getNetworkConfig();
        params = new HelperVaultTest(config).createFixedYieldVaultParams();

        params.kycParams.kycProvider = address(kycProvider);
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
        factory.allowCustodian(params.maturityVaultParams.baseVaultParams.custodian);

        vm.prank(config.factoryParams.operator);
        CredbullFixedYieldVault vault = CredbullFixedYieldVault(payable(factory.createVault(params, OPTIONS)));

        assertEq(vault.asset(), address(params.maturityVaultParams.baseVaultParams.asset));
        assertEq(vault.name(), params.maturityVaultParams.baseVaultParams.shareName);
        assertEq(vault.symbol(), params.maturityVaultParams.baseVaultParams.shareSymbol);
        assertEq(address(vault.kycProvider()), params.kycParams.kycProvider);
        assertEq(vault.CUSTODIAN(), params.maturityVaultParams.baseVaultParams.custodian);
    }

    function test__ShouldRevertCreateVaultOnUnAuthorizedUser() public {
        vm.prank(config.factoryParams.owner);
        vm.expectRevert();
        factory.createVault(params, OPTIONS);
    }

    function test__ShouldAllowAdminToChangeOperator() public {
        address newOperator = makeAddr("new_operator");

        vm.startPrank(config.factoryParams.owner);
        factory.allowCustodian(params.maturityVaultParams.baseVaultParams.custodian);
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
        factory.allowCustodian(params.maturityVaultParams.baseVaultParams.custodian);

        params.maturityVaultParams.baseVaultParams.custodian = makeAddr("randomCustodian");

        vm.prank(config.factoryParams.operator);
        vm.expectRevert(CredbullVaultFactory.CredbullVaultFactory__CustodianNotAllowed.selector);
        factory.createVault(params, OPTIONS);
    }

    function test__ShouldAllowAdminToAddCustodians() public {
        vm.prank(config.factoryParams.owner);
        factory.allowCustodian(params.maturityVaultParams.baseVaultParams.custodian);

        assertTrue(factory.isCustodianAllowed(params.maturityVaultParams.baseVaultParams.custodian));
    }

    function test__ShoulRemoveCustodianIfExist() public {
        vm.startPrank(config.factoryParams.owner);
        factory.allowCustodian(params.maturityVaultParams.baseVaultParams.custodian);
        assertTrue(factory.isCustodianAllowed(params.maturityVaultParams.baseVaultParams.custodian));

        factory.removeCustodian(params.maturityVaultParams.baseVaultParams.custodian);
        assertTrue(!factory.isCustodianAllowed(params.maturityVaultParams.baseVaultParams.custodian));
        vm.stopPrank();
    }

    function test__ShouldRevertAllowAdmingIfNotOwner() public {
        vm.prank(makeAddr("random_addr"));
        vm.expectRevert();
        factory.allowCustodian(params.maturityVaultParams.baseVaultParams.custodian);
    }

    function createVault() internal returns (CredbullFixedYieldVault vault) {
        vm.prank(config.factoryParams.owner);
        factory.allowCustodian(params.maturityVaultParams.baseVaultParams.custodian);

        vm.prank(config.factoryParams.operator);
        vault = CredbullFixedYieldVault(payable(factory.createVault(params, OPTIONS)));
    }
}
