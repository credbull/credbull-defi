//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";

import { HelperConfig } from "@script/HelperConfig.s.sol";

import { Vault } from "@credbull/vault/Vault.sol";
import { WindowPlugin } from "@credbull/plugin/WindowPlugin.sol";

import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";
import { SimpleWindowVault } from "@test/test/vault/SimpleWindowVault.t.sol";
import { ParamsFactory } from "@test/test/vault/utils/ParamsFactory.t.sol";

contract WindowPluginTest is Test {
    SimpleWindowVault private vault;

    Vault.VaultParams private vaultParams;
    WindowPlugin.WindowPluginParams private windowParams;
    HelperConfig private helperConfig;

    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");

    uint256 private constant INITIAL_BALANCE = 1e6;
    uint256 private precision;

    function setUp() public {
        helperConfig = new HelperConfig(true);
        ParamsFactory pf = new ParamsFactory(helperConfig.getNetworkConfig());
        vaultParams = pf.createVaultParams();
        windowParams = pf.createWindowPluginParams();

        vault = new SimpleWindowVault(vaultParams, windowParams);
        precision = 10 ** SimpleUSDC(address(vaultParams.asset)).decimals();

        SimpleUSDC(address(vaultParams.asset)).mint(alice, INITIAL_BALANCE * precision);
        SimpleUSDC(address(vaultParams.asset)).mint(bob, INITIAL_BALANCE * precision);
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
        vault.toggleWindowCheck();

        deposit(alice, 10 * precision);
        assertEq(vault.balanceOf(alice), 10 * precision);
    }

    function test__WindowVault__ShouldToggleWhiteList() public {
        bool beforeToggle = vault.checkWindow();
        vault.toggleWindowCheck();
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

        vm.expectEmit();
        emit WindowPlugin.WindowUpdated(newDepositOpen, newDepositClose, newWithdrawOpen, newWithdrawClose);
        vault.updateWindow(newDepositOpen, newDepositClose, newWithdrawOpen, newWithdrawClose);

        assertTrue(vault.depositOpensAtTimestamp() == newDepositOpen);
        assertTrue(vault.depositClosesAtTimestamp() == newDepositClose);
        assertTrue(vault.redemptionOpensAtTimestamp() == newWithdrawOpen);
        assertTrue(vault.redemptionClosesAtTimestamp() == newWithdrawClose);
    }

    function test__WindowVault__RevertOnIncorrectWindowParams() public {
        // Withdraw window opens before deposit window
        uint256 newDepositOpen = 100;
        uint256 newDepositClose = 300;
        uint256 newWithdrawOpen = 200;
        uint256 newWithdrawClose = 400;

        // Deposit window closes before it opens
        uint256 newDepositOpen_1 = 300;
        uint256 newDepositClose_1 = 100;
        uint256 newWithdrawOpen_1 = 200;
        uint256 newWithdrawClose_1 = 400;

        WindowPlugin.WindowPluginParams memory localWindowParams = WindowPlugin.WindowPluginParams({
            depositWindow: WindowPlugin.Window({ opensAt: newDepositOpen, closesAt: newDepositClose }),
            redemptionWindow: WindowPlugin.Window({ opensAt: newWithdrawOpen, closesAt: newWithdrawClose })
        });

        vm.expectRevert(
            abi.encodeWithSelector(
                WindowPlugin.WindowPlugin__IncorrectWindowValues.selector,
                newDepositOpen,
                newDepositClose,
                newWithdrawOpen,
                newWithdrawClose
            )
        );
        vault.updateWindow(newDepositOpen, newDepositClose, newWithdrawOpen, newWithdrawClose);

        vm.expectRevert(
            abi.encodeWithSelector(
                WindowPlugin.WindowPlugin__IncorrectWindowValues.selector,
                newDepositOpen_1,
                newDepositClose_1,
                newWithdrawOpen_1,
                newWithdrawClose_1
            )
        );
        vault.updateWindow(newDepositOpen_1, newDepositClose_1, newWithdrawOpen_1, newWithdrawClose_1);

        {
            // Withdraw window closes before it opens
            uint256 newDepositOpen_2 = 100;
            uint256 newDepositClose_2 = 300;
            uint256 newWithdrawOpen_2 = 400;
            uint256 newWithdrawClose_2 = 200;
            vm.expectRevert(
                abi.encodeWithSelector(
                    WindowPlugin.WindowPlugin__IncorrectWindowValues.selector,
                    newDepositOpen_2,
                    newDepositClose_2,
                    newWithdrawOpen_2,
                    newWithdrawClose_2
                )
            );
            vault.updateWindow(newDepositOpen_2, newDepositClose_2, newWithdrawOpen_2, newWithdrawClose_2);
        }

        //checking modifier on constructor
        vm.expectRevert(
            abi.encodeWithSelector(
                WindowPlugin.WindowPlugin__IncorrectWindowValues.selector,
                newDepositOpen,
                newDepositClose,
                newWithdrawOpen,
                newWithdrawClose
            )
        );
        new SimpleWindowVault(vaultParams, localWindowParams);
    }

    function deposit(address user, uint256 assets) internal returns (uint256 shares) {
        // first, approve the deposit
        vm.startPrank(user);
        vaultParams.asset.approve(address(vault), assets);

        shares = vault.deposit(assets, user);
        vm.stopPrank();
    }
}
