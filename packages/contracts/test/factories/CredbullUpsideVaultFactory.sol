//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";

import { HelperVaultTest } from "../base/HelperVaultTest.t.sol";
import { CredbullUpsideVaultFactory } from "../../src/factories/CredbullUpsideVaultFactory.sol";
import { DeployVaultFactory } from "../../script/DeployVaultFactory.s.sol";
import { HelperConfig, NetworkConfig } from "../../script/HelperConfig.s.sol";
import { ICredbull } from "../../src/interface/ICredbull.sol";
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

    function test__CreateUpsideVaultFromFactory() public {
        NetworkConfig memory config = helperConfig.getNetworkConfig();
        ICredbull.VaultParams memory params = new HelperVaultTest(helperConfig).createTestVaultParams();

        params.kycProvider = address(kycProvider);

        vm.prank(config.factoryParams.owner);
        factory.allowCustodian(params.custodian);

        vm.prank(config.factoryParams.operator);
        CredbullFixedYieldVaultWithUpside vault = CredbullFixedYieldVaultWithUpside(
            factory.createVault(params, config.factoryParams.collateralPercentage, OPTIONS)
        );

        assertEq(vault.asset(), address(params.asset));
        assertEq(vault.name(), params.shareName);
        assertEq(vault.symbol(), params.shareSymbol);
        assertEq(address(vault.kycProvider()), params.kycProvider);
        assertEq(vault.CUSTODIAN(), params.custodian);
    }
}
