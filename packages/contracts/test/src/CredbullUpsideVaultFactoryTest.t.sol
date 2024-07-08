//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";

import { DeployVaultFactory } from "@script/DeployVaultFactory.s.sol";
import { HelperConfig, NetworkConfig } from "@script/HelperConfig.s.sol";

import { UpsideVault } from "@credbull/vault/UpsideVault.sol";
import { CredbullFixedYieldVaultWithUpside } from "@credbull/CredbullFixedYieldVaultWithUpside.sol";
import { CredbullWhiteListProvider } from "@credbull/CredbullWhiteListProvider.sol";
import { CredbullUpsideVaultFactory } from "@credbull/CredbullUpsideVaultFactory.sol";
import { ParamsFactory } from "@test/test/vault/utils/ParamsFactory.t.sol";

contract CredbullUpsideVaultFactoryTest is Test {
    CredbullUpsideVaultFactory private factory;
    DeployVaultFactory private deployer;
    HelperConfig private helperConfig;
    CredbullWhiteListProvider private whiteListProvider;

    string private OPTIONS = "{}";

    function setUp() public {
        deployer = new DeployVaultFactory();
        (, factory, whiteListProvider, helperConfig) = deployer.runTest();
    }

    function test__CredbullUpsideVaultFactory__ShouldSuccessfullyCreateFactoryUpside() public {
        NetworkConfig memory config = helperConfig.getNetworkConfig();
        address[] memory custodians = new address[](1);
        custodians[0] = config.factoryParams.custodian;
        CredbullUpsideVaultFactory vaultFactory =
            new CredbullUpsideVaultFactory(config.factoryParams.owner, config.factoryParams.operator, custodians);
        vaultFactory.hasRole(vaultFactory.OPERATOR_ROLE(), config.factoryParams.operator);
    }

    function test__CredbullUpsideVaultFactory__CreateUpsideVaultFromFactory() public {
        NetworkConfig memory config = helperConfig.getNetworkConfig();
        (UpsideVault.UpsideVaultParams memory params) = new ParamsFactory(config).createUpsideVaultParams();

        params.fixedYieldVault.whiteListPlugin.whiteListProvider = address(whiteListProvider);

        vm.prank(config.factoryParams.owner);
        factory.allowCustodian(params.fixedYieldVault.maturityVault.vault.custodian);

        vm.prank(config.factoryParams.operator);
        CredbullFixedYieldVaultWithUpside vault =
            CredbullFixedYieldVaultWithUpside(payable(factory.createVault(params, OPTIONS)));

        assertEq(vault.asset(), address(params.fixedYieldVault.maturityVault.vault.asset));
        assertEq(vault.name(), params.fixedYieldVault.maturityVault.vault.shareName);
        assertEq(vault.symbol(), params.fixedYieldVault.maturityVault.vault.shareSymbol);
        assertEq(address(vault.whiteListProvider()), params.fixedYieldVault.whiteListPlugin.whiteListProvider);
        assertEq(vault.CUSTODIAN(), params.fixedYieldVault.maturityVault.vault.custodian);
    }
}
