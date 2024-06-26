//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";

import { DeployVaultFactory } from "@script/DeployVaultFactory.s.sol";
import { HelperConfig, NetworkConfig } from "@script/HelperConfig.s.sol";

import { UpsideVault } from "@src/vault/UpsideVault.sol";
import { CredbullFixedYieldVaultWithUpside } from "@src/CredbullFixedYieldVaultWithUpside.sol";
import { CredbullKYCProvider } from "@src/CredbullKYCProvider.sol";
import { CredbullUpsideVaultFactory } from "@src/CredbullUpsideVaultFactory.sol";
import { ParametersFactory } from "@test/test/vault/ParametersFactory.t.sol";

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
        (UpsideVault.UpsideVaultParameters memory params) = new ParametersFactory(config).createUpsideVaultParameters();

        params.fixedYieldVault.whitelistPlugIn.kycProvider = address(kycProvider);

        vm.prank(config.factoryParams.owner);
        factory.allowCustodian(params.fixedYieldVault.maturityVault.vault.custodian);

        vm.prank(config.factoryParams.operator);
        CredbullFixedYieldVaultWithUpside vault =
            CredbullFixedYieldVaultWithUpside(payable(factory.createVault(params, OPTIONS)));

        assertEq(vault.asset(), address(params.fixedYieldVault.maturityVault.vault.asset));
        assertEq(vault.name(), params.fixedYieldVault.maturityVault.vault.shareName);
        assertEq(vault.symbol(), params.fixedYieldVault.maturityVault.vault.shareSymbol);
        assertEq(address(vault.kycProvider()), params.fixedYieldVault.whitelistPlugIn.kycProvider);
        assertEq(vault.CUSTODIAN(), params.fixedYieldVault.maturityVault.vault.custodian);
    }
}
