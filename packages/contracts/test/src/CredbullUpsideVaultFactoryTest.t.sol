//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { UpsideVault } from "@credbull/vault/UpsideVault.sol";
import { CredbullFixedYieldVaultWithUpside } from "@credbull/CredbullFixedYieldVaultWithUpside.sol";
import { CredbullWhiteListProvider } from "@credbull/CredbullWhiteListProvider.sol";
import { CredbullUpsideVaultFactory } from "@credbull/CredbullUpsideVaultFactory.sol";

import { DeployVaults } from "@script/DeployVaults.s.sol";
import { DeployVaultsSupport } from "@script/DeployVaultsSupport.s.sol";

import { VaultsSupportConfig } from "@script/TomlConfig.s.sol";

import { ParamsFactory } from "@test/test/vault/utils/ParamsFactory.t.sol";

contract CredbullUpsideVaultFactoryTest is Test, VaultsSupportConfig {
    DeployVaults private deployer;
    DeployVaultsSupport private supportDeployer;

    CredbullUpsideVaultFactory private factory;
    CredbullWhiteListProvider private whiteListProvider;
    ParamsFactory private paramsFactory;

    string private OPTIONS = "{}";

    function setUp() public {
        deployer = new DeployVaults().skipDeployCheck();
        supportDeployer = new DeployVaultsSupport().skipDeployCheck();

        (, factory, whiteListProvider) = deployer.run();
        (ERC20 cbl, ERC20 usdc,) = supportDeployer.run();

        paramsFactory = new ParamsFactory(usdc, cbl);
    }

    function test__CredbullUpsideVaultFactory__ShouldSuccessfullyCreateFactoryUpside() public {
        address[] memory custodians = new address[](1);
        custodians[0] = custodian();
        CredbullUpsideVaultFactory vaultFactory = new CredbullUpsideVaultFactory(owner(), operator(), custodians);
        vaultFactory.hasRole(vaultFactory.OPERATOR_ROLE(), operator());
    }

    function test__CredbullUpsideVaultFactory__CreateUpsideVaultFromFactory() public {
        (UpsideVault.UpsideVaultParams memory params) = paramsFactory.createUpsideVaultParams();

        params.fixedYieldVault.whiteListPlugin.whiteListProvider = address(whiteListProvider);

        vm.prank(owner());
        factory.allowCustodian(params.fixedYieldVault.maturityVault.vault.custodian);

        vm.prank(operator());
        CredbullFixedYieldVaultWithUpside vault =
            CredbullFixedYieldVaultWithUpside(payable(factory.createVault(params, OPTIONS)));

        assertEq(vault.asset(), address(params.fixedYieldVault.maturityVault.vault.asset));
        assertEq(vault.name(), params.fixedYieldVault.maturityVault.vault.shareName);
        assertEq(vault.symbol(), params.fixedYieldVault.maturityVault.vault.shareSymbol);
        assertEq(address(vault.WHITELIST_PROVIDER()), params.fixedYieldVault.whiteListPlugin.whiteListProvider);
        assertEq(vault.CUSTODIAN(), params.fixedYieldVault.maturityVault.vault.custodian);
    }
}
