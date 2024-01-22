//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { CredbullVaultFactory } from "../src/CredbullVaultFactory.sol";
import { DeployVaultFactory } from "../script/DeployVaultFactory.s.sol";
import { HelperConfig, NetworkConfig } from "../script/HelperConfig.s.sol";
import { ICredbull } from "../src/interface/ICredbull.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { CredbullVault } from "../src/CredbullVault.sol";

contract CredbullVaultFactoryTest is Test {
    CredbullVaultFactory factory;
    DeployVaultFactory private deployer;
    HelperConfig private helperConfig;

    function setUp() public {
        deployer = new DeployVaultFactory();
        (factory, helperConfig) = deployer.run();
    }

    function test__CreateVaultFromFactory() public {
        NetworkConfig memory config = helperConfig.getNetworkConfig();
        ICredbull.VaultParams memory params = config.vaultParams;

        vm.prank(params.owner);
        CredbullVault vault = factory.createVault(params);

        assertEq(vault.owner(), params.owner);
        assertEq(vault.asset(), address(params.asset));
        assertEq(vault.name(), params.shareName);
        assertEq(vault.symbol(), params.shareSymbol);
        assertEq(address(vault.kycProvider()), params.kycProvider);
        assertEq(vault.custodian(), params.custodian);
    }
}
