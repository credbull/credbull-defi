//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { CredbullVaultFactory } from "../src/CredbullVaultFactory.sol";
import { CredbullUpsideVaultFactory } from "../src/CredbullUpsideVaultFactory.sol";
import { CredbullUpsideVault } from "../src/CredbullUpsideVault.sol";
import { DeployVaultFactory } from "../script/DeployVaultFactory.s.sol";
import { HelperConfig, NetworkConfig } from "../script/HelperConfig.s.sol";
import { ICredbull } from "../src/interface/ICredbull.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { CredbullVault } from "../src/CredbullVault.sol";
import { console2 } from "forge-std/console2.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { MockToken } from "./mocks/MockToken.sol";
import { MockStablecoin } from "./mocks/MockStablecoin.sol";

contract CredbullUpsideVaultFactoryTest is Test {
    CredbullVaultFactory private factory;
    CredbullUpsideVaultFactory private uFactory;
    CredbullUpsideVault private vault;
    CredbullVault private baseVault;
    CredbullVault private upsideVault;
    MockToken private token;
    HelperConfig private helperConfig;

    Account private user;

    ICredbull.VaultParams private params;

    function setUp() public {
        user = makeAccount("user");
        DeployVaultFactory deployer = new DeployVaultFactory();
        (factory, helperConfig) = deployer.runTest();

        NetworkConfig memory config = helperConfig.getNetworkConfig();
        params = config.vaultParams;

        vm.prank(config.factoryParams.operator);
        baseVault = factory.createVault(params, "{}");
        setRule(baseVault, false, false, false);

        vm.prank(config.factoryParams.operator);
        upsideVault = factory.createVault(params, "{}");
        setRule(upsideVault, false, false, false);

        token = new MockToken(type(uint128).max);
        uFactory = new CredbullUpsideVaultFactory(config.factoryParams.owner, config.factoryParams.operator);

        vm.prank(config.factoryParams.operator);
        vault = uFactory.createUpsideVault(address(baseVault), address(upsideVault), address(token));
    }

    function test__deposit_should_succeed() public {
        MockStablecoin(address(params.asset)).mint(user.addr, 1000 ether);
        token.mint(user.addr, 1000 ether);

        vm.startPrank(user.addr);
        params.asset.approve(address(upsideVault), 1000 ether);
        token.approve(address(vault), 1000 ether);

        vm.warp(params.depositOpensAt);

        vault.deposit(1000 ether, user.addr, true);
        vm.stopPrank();

        assertEq(vault.balanceOf(user.addr), 1000 ether);
        assertEq(params.asset.balanceOf(user.addr), 0 ether);
    }

    function setRule(CredbullVault _vault, bool maturity, bool vaultOpen, bool whitelist) internal {
        CredbullVault.Rules memory rules =
            CredbullVault.Rules({ checkMaturity: maturity, checkVaultOpenStatus: vaultOpen, checkWhitelist: whitelist });

        vm.prank(params.owner);
        _vault.setRules(rules);
    }
}
