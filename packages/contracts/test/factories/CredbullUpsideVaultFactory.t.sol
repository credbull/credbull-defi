//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";

import { HelperVaultTest } from "../base/HelperVaultTest.t.sol";
import { CredbullUpsideVaultFactory } from "../../src/factories/CredbullUpsideVaultFactory.sol";
import { DeployVaultFactory } from "../../script/DeployVaultFactory.s.sol";
import { HelperConfig, NetworkConfig } from "../../script/HelperConfig.s.sol";
import { CredbullFixedYieldVaultWithUpside } from "../../src/CredbullFixedYieldVaultWithUpside.sol";
import { CredbullKYCProvider } from "../../src/CredbullKYCProvider.sol";

contract CredbullVaultWithUpsideFactoryTest is Test {
    CredbullUpsideVaultFactory private factory;
    DeployVaultFactory private deployer;
    HelperConfig private helperConfig;
    CredbullKYCProvider private kycProvider;

    string private OPTIONS = "{}";

    function setUp() public {
        deployer = new DeployVaultFactory();
        (, factory, kycProvider, helperConfig) = deployer.runTest();
    }

    function test__ShouldSuccefullyCreateFactoryUpside() public {
        NetworkConfig memory config = helperConfig.getNetworkConfig();
        address[] memory custodians = new address[](1);
        custodians[0] = config.factoryParams.custodian;
        CredbullUpsideVaultFactory vaultFactory =
            new CredbullUpsideVaultFactory(config.factoryParams.owner, config.factoryParams.operator, custodians);
        vaultFactory.hasRole(vaultFactory.OPERATOR_ROLE(), config.factoryParams.operator);
    }

    function test__CreateUpsideVaultFromFactory() public {
        NetworkConfig memory config = helperConfig.getNetworkConfig();
        (CredbullFixedYieldVaultWithUpside.UpsideVaultParams memory params) =
            new HelperVaultTest(config).createFixedYieldWithUpsideVaultParams();

        params.fixedYieldVaultParams.kycParams.kycProvider = address(kycProvider);

        vm.prank(config.factoryParams.owner);
        factory.allowCustodian(params.fixedYieldVaultParams.maturityVaultParams.baseVaultParams.custodian);

        vm.prank(config.factoryParams.operator);
        CredbullFixedYieldVaultWithUpside vault =
            CredbullFixedYieldVaultWithUpside(payable(factory.createVault(params, OPTIONS)));

        assertEq(vault.asset(), address(params.fixedYieldVaultParams.maturityVaultParams.baseVaultParams.asset));
        assertEq(vault.name(), params.fixedYieldVaultParams.maturityVaultParams.baseVaultParams.shareName);
        assertEq(vault.symbol(), params.fixedYieldVaultParams.maturityVaultParams.baseVaultParams.shareSymbol);
        assertEq(address(vault.kycProvider()), params.fixedYieldVaultParams.kycParams.kycProvider);
        assertEq(vault.CUSTODIAN(), params.fixedYieldVaultParams.maturityVaultParams.baseVaultParams.custodian);
    }
}
