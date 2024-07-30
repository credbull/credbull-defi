//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { Vault } from "@credbull/vault/Vault.sol";
import { WindowPlugin } from "@credbull/plugin/WindowPlugin.sol";

import { DeployVaultsSupport } from "@script/DeployVaults.s.sol";
import { VaultsSupportConfigured } from "@script/Configured.s.sol";

import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";
import { SimpleWindowVault } from "@test/test/vault/SimpleWindowVault.t.sol";
import { ParamsFactory } from "@test/test/vault/utils/ParamsFactory.t.sol";

contract WindowPluginTest is Test, VaultsSupportConfigured {
    DeployVaultsSupport private deployer;

    SimpleWindowVault private vault;

    Vault.VaultParams private vaultParams;
    WindowPlugin.WindowPluginParams private windowParams;

    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");

    uint256 private constant INITIAL_BALANCE = 1e6;
    uint256 private precision;

    function setUp() public {
        deployer = new DeployVaultsSupport();
        (ERC20 cbl, ERC20 usdc,) = deployer.deploy(true);

        ParamsFactory pf = new ParamsFactory(usdc, cbl);
        vaultParams = pf.createVaultParams();
        windowParams = pf.createWindowPluginParams();

        vault = new SimpleWindowVault(vaultParams, windowParams);

        SimpleUSDC asset = SimpleUSDC(address(vaultParams.asset));
        precision = 10 ** asset.decimals();

        asset.mint(alice, INITIAL_BALANCE * precision);
        asset.mint(bob, INITIAL_BALANCE * precision);
    }

    function test__WindowVault__RevertDepositIfBehindWindow() public {
        // given that the vault's deposit window is in the future
        vm.warp(windowParams.depositWindow.opensAt - 1);

        // when Alice try to deposit 10 tokens
        // then the deposit should be reverted
        vm.startPrank(alice);
        vaultParams.asset.approve(address(vault), 10 * precision);
        vm.expectRevert(
            abi.encodeWithSelector(
                WindowPlugin.CredbullVault__OperationOutsideRequiredWindow.selector,
                windowParams.depositWindow.opensAt,
                windowParams.depositWindow.closesAt,
                block.timestamp
            )
        );
        vault.deposit(10 * precision, alice);
    }

    function test__WindowVault__RevertDepositIfAheadOfWindow() public {
        // given that the vault's deposit window is in the past
        vm.warp(windowParams.depositWindow.closesAt + 1);

        // when Alice try to deposit 10 tokens
        // then the deposit should be reverted
        vm.startPrank(alice);
        vaultParams.asset.approve(address(vault), 10 * precision);
        vm.expectRevert(
            abi.encodeWithSelector(
                WindowPlugin.CredbullVault__OperationOutsideRequiredWindow.selector,
                windowParams.depositWindow.opensAt,
                windowParams.depositWindow.closesAt,
                block.timestamp
            )
        );
        vault.deposit(10 * precision, alice);
        vm.stopPrank();
    }

    function test__WindowVault__DepositSuccessOnWindowOpen() public {
        // given that we are in the vault's deposit window
        // when Alice try to deposit 10 * precision
        // then the deposit should be reverted
        deposit(alice, 10 * precision);
        assertEq(vault.balanceOf(alice), 10 * precision);
    }

    function test__WindowVault__RevertWithdrawIfAheadOfWindow() public {
        uint256 shares = deposit(alice, 10 * precision);
        vm.startPrank(alice);

        // given that the vault's redemption window is in the past
        vm.warp(windowParams.redemptionWindow.closesAt + 1);

        // when Alice try to redeem 10 * precision
        // then the redemption should be reverted
        vm.expectRevert(
            abi.encodeWithSelector(
                WindowPlugin.CredbullVault__OperationOutsideRequiredWindow.selector,
                windowParams.redemptionWindow.opensAt,
                windowParams.redemptionWindow.closesAt,
                block.timestamp
            )
        );
        vault.redeem(shares, alice, alice);
        vm.stopPrank();
    }

    function test__WindowVault__WithdrawSuccessOnWindowOpen() public {
        uint256 shares = deposit(alice, 10 * precision);
        assertEq(vault.balanceOf(alice), 10 * precision);

        SimpleUSDC token = SimpleUSDC(address(vaultParams.asset));
        token.mint(address(vault), 10 * precision);

        vm.startPrank(alice);
        // given that the vault's redemption window is in the future
        // when Alice try to redeem 10 * precision
        // then the redemption should be reverted
        vm.warp(windowParams.redemptionWindow.opensAt + 1);
        vault.redeem(shares, alice, alice);
        vm.stopPrank();
        assertEq(vault.balanceOf(alice), 0);
    }

    function test__WindowVault__RevertWithdrawIfBehindWindow() public {
        uint256 shares = deposit(alice, 10 * precision);
        vm.startPrank(alice);
        // given that the vault's redemption window is in the future
        // when Alice try to redeem 10 * precision
        // then the redemption should be reverted
        vm.expectRevert(
            abi.encodeWithSelector(
                WindowPlugin.CredbullVault__OperationOutsideRequiredWindow.selector,
                windowParams.redemptionWindow.opensAt,
                windowParams.redemptionWindow.closesAt,
                block.timestamp
            )
        );
        vault.redeem(shares, alice, alice);
        vm.stopPrank();
    }

    function test__WindowVault__ShouldNotRevertOnWindowModifier() public {
        vault.toggleWindowCheck(false);

        deposit(alice, 10 * precision);
        assertEq(vault.balanceOf(alice), 10 * precision);
    }

    function test__WindowVault__ShouldToggleWhiteList() public {
        bool beforeToggle = vault.checkWindow();
        vault.toggleWindowCheck(!beforeToggle);
        bool afterToggle = vault.checkWindow();
        assertEq(afterToggle, !beforeToggle);
    }

    function test__WindowVault__ShouldUpdateWindowValues() public {
        uint256 newDepositOpen = 100;
        uint256 newDepositClose = 200;
        uint256 newWithdrawOpen = 300;
        uint256 newWithdrawClose = 400;

        uint256 currentDepositOpen = vault.depositOpensAtTimestamp();
        uint256 currentDepositClose = vault.depositClosesAtTimestamp();
        uint256 currentWithdrawOpen = vault.redemptionOpensAtTimestamp();
        uint256 currentWithdrawClose = vault.redemptionClosesAtTimestamp();

        assertTrue(currentDepositOpen != newDepositOpen);
        assertTrue(currentDepositClose != newDepositClose);
        assertTrue(currentWithdrawOpen != newWithdrawOpen);
        assertTrue(currentWithdrawClose != newWithdrawClose);

        vault.updateWindow(newDepositOpen, newDepositClose, newWithdrawOpen, newWithdrawClose);

        assertTrue(vault.depositOpensAtTimestamp() == newDepositOpen);
        assertTrue(vault.depositClosesAtTimestamp() == newDepositClose);
        assertTrue(vault.redemptionOpensAtTimestamp() == newWithdrawOpen);
        assertTrue(vault.redemptionClosesAtTimestamp() == newWithdrawClose);
    }

    function deposit(address user, uint256 assets) internal returns (uint256 shares) {
        // first, approve the deposit
        vm.startPrank(user);
        vaultParams.asset.approve(address(vault), assets);

        shares = vault.deposit(assets, user);
        vm.stopPrank();
    }
}
