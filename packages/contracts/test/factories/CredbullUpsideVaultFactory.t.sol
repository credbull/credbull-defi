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
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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
        (ICredbull.FixedYieldVaultParams memory params, IERC20 token) =
            new HelperVaultTest(config).createFixedYieldWithUpsideVaultParams();

        params.kycParams.kycProvider = address(kycProvider);

        vm.prank(config.factoryParams.owner);
        factory.allowCustodian(params.baseVaultParams.custodian);

        vm.prank(config.factoryParams.operator);
        CredbullFixedYieldVaultWithUpside vault = CredbullFixedYieldVaultWithUpside(
            payable(factory.createVault(params, token, config.factoryParams.collateralPercentage, OPTIONS))
        );

        assertEq(vault.asset(), address(params.baseVaultParams.asset));
        assertEq(vault.name(), params.baseVaultParams.shareName);
        assertEq(vault.symbol(), params.baseVaultParams.shareSymbol);
        assertEq(address(vault.kycProvider()), params.kycParams.kycProvider);
        assertEq(vault.CUSTODIAN(), params.baseVaultParams.custodian);
    }
}
