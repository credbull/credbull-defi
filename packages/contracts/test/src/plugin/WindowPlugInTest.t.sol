//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";

import { HelperConfig } from "@script/HelperConfig.s.sol";

import { Vault } from "@src/vault/Vault.sol";
import { WindowPlugIn } from "@src/plugin/WindowPlugIn.sol";

import { MockStablecoin } from "@test/test/mock/MockStablecoin.t.sol";
import { MockWindowVault } from "@test/test/mock/vault/MockWindowVault.t.sol";
import { ParametersFactory } from "@test/test/vault/ParametersFactory.t.sol";

contract WindowPlugInTest is Test {
    MockWindowVault private vault;

    Vault.VaultParameters private vaultParams;
    WindowPlugIn.WindowPlugInParameters private windowParams;
    HelperConfig private helperConfig;

    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");

    uint256 private constant INITIAL_BALANCE = 1e6;
    uint256 private precision;

    function setUp() public {
        helperConfig = new HelperConfig(true);
        ParametersFactory pf = new ParametersFactory(helperConfig.getNetworkConfig());
        vaultParams = pf.createVaultParameters();
        windowParams = pf.createWindowPlugInParameters();

        vault = new MockWindowVault(vaultParams, windowParams);
        precision = 10 ** MockStablecoin(address(vaultParams.asset)).decimals();

        MockStablecoin(address(vaultParams.asset)).mint(alice, INITIAL_BALANCE * precision);
        MockStablecoin(address(vaultParams.asset)).mint(bob, INITIAL_BALANCE * precision);
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
                WindowPlugIn.CredbullVault__OperationOutsideRequiredWindow.selector,
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
                WindowPlugIn.CredbullVault__OperationOutsideRequiredWindow.selector,
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
                WindowPlugIn.CredbullVault__OperationOutsideRequiredWindow.selector,
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

        MockStablecoin token = MockStablecoin(address(vaultParams.asset));
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
                WindowPlugIn.CredbullVault__OperationOutsideRequiredWindow.selector,
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

    function test__WindowVault__ShouldToggleWhitelist() public {
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
