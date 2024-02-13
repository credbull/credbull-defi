//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { WindowVaultMock } from "../mocks/vaults/WindowVaultMock.m.sol";
import { ICredbull } from "../../src/interface/ICredbull.sol";
import { NetworkConfig, HelperConfig } from "../../script/HelperConfig.s.sol";
import { MockStablecoin } from "../mocks/MockStablecoin.sol";
import { WindowPlugIn } from "../../src/plugins/WindowPlugIn.sol";

contract WindowPlugInTest is Test {
    WindowVaultMock private vault;

    ICredbull.VaultParams private vaultParams;
    HelperConfig private helperConfig;

    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");

    uint256 private constant INITIAL_BALANCE = 1000 ether;

    function setUp() public {
        helperConfig = new HelperConfig(true);
        NetworkConfig memory config = helperConfig.getNetworkConfig();
        vaultParams = config.vaultParams;
        vault = new WindowVaultMock(vaultParams);

        MockStablecoin(address(vaultParams.asset)).mint(alice, INITIAL_BALANCE);
        MockStablecoin(address(vaultParams.asset)).mint(bob, INITIAL_BALANCE);
    }

    function test__WindowVault__RevertDepositIfBehindWindow() public {
        // given that the vault's deposit window is in the future
        // when Alice try to deposit 10 ether
        // then the deposit should be reverted
        vm.expectRevert(
            abi.encodeWithSelector(
                WindowPlugIn.CredbullVault__OperationOutsideRequiredWindow.selector,
                vaultParams.depositOpensAt,
                vaultParams.depositClosesAt,
                block.timestamp
            )
        );
        vault.deposit(10 ether, alice);
    }

    function test__WindowVault__RevertDepositIfAheadOfWindow() public {
        // given that the vault's deposit window is in the past
        vm.warp(vaultParams.depositClosesAt + 1);

        // when Alice try to deposit 10 ether
        // then the deposit should be reverted
        vm.startPrank(alice);
        vaultParams.asset.approve(address(vault), 10 ether);
        vm.expectRevert(
            abi.encodeWithSelector(
                WindowPlugIn.CredbullVault__OperationOutsideRequiredWindow.selector,
                vaultParams.depositOpensAt,
                vaultParams.depositClosesAt,
                block.timestamp
            )
        );
        vault.deposit(10 ether, alice);
        vm.stopPrank();
    }

    function test__WindowVault__DepositSuccessOnWindowOpen() public {
        // given that we are in the vault's deposit window
        // when Alice try to deposit 10 ether
        // then the deposit should be reverted
        deposit(alice, 10 ether, true);
        assertEq(vault.balanceOf(alice), 10 ether);
    }

    function test__WindowVault__RevertWithdrawIfAheadOfWindow() public {
        uint256 shares = deposit(alice, 10 ether, true);
        vm.startPrank(alice);

        // given that the vault's redemption window is in the past
        vm.warp(vaultParams.redemptionClosesAt + 1);

        // when Alice try to redeem 10 ether
        // then the redemption should be reverted
        vm.expectRevert(
            abi.encodeWithSelector(
                WindowPlugIn.CredbullVault__OperationOutsideRequiredWindow.selector,
                vaultParams.redemptionOpensAt,
                vaultParams.redemptionClosesAt,
                block.timestamp
            )
        );
        vault.redeem(shares, alice, alice);
        vm.stopPrank();
    }

    function test__WindowVault__WithdrawSuccessOnWindowOpen() public {
        uint256 shares = deposit(alice, 10 ether, true);
        assertEq(vault.balanceOf(alice), 10 ether);

        MockStablecoin token = MockStablecoin(address(vaultParams.asset));
        token.mint(address(vault), 10 ether);

        vm.startPrank(alice);
        // given that the vault's redemption window is in the future
        // when Alice try to redeem 10 ether
        // then the redemption should be reverted
        vm.warp(vaultParams.redemptionOpensAt + 1);
        vault.redeem(shares, alice, alice);
        vm.stopPrank();
        assertEq(vault.balanceOf(alice), 0 ether);
    }

    function test__WindowVault__RevertWithdrawIfBehindWindow() public {
        uint256 shares = deposit(alice, 10 ether, true);
        vm.startPrank(alice);
        // given that the vault's redemption window is in the future
        // when Alice try to redeem 10 ether
        // then the redemption should be reverted
        vm.expectRevert(
            abi.encodeWithSelector(
                WindowPlugIn.CredbullVault__OperationOutsideRequiredWindow.selector,
                vaultParams.redemptionOpensAt,
                vaultParams.redemptionClosesAt,
                block.timestamp
            )
        );
        vault.redeem(shares, alice, alice);
        vm.stopPrank();
    }

    function test__WindowVault__ShouldNotRevertOnWindowModifier() public {
        vault.toggleWindowCheck(false);

        deposit(alice, 10 ether, false);
        assertEq(vault.balanceOf(alice), 10 ether);
    }

    function test__WindowVault__ShouldToggleWhitelist() public {
        bool beforeToggle = vault.checkWindow();
        vault.toggleWindowCheck(!beforeToggle);
        bool afterToggle = vault.checkWindow();
        assertEq(afterToggle, !beforeToggle);
    }

    function deposit(address user, uint256 assets, bool warp) internal returns (uint256 shares) {
        // first, approve the deposit
        vm.startPrank(user);
        vaultParams.asset.approve(address(vault), assets);

        // now we can deposit, alice is the caller and receiver
        if (warp) {
            vm.warp(vaultParams.depositOpensAt);
        }

        shares = vault.deposit(assets, alice);
        vm.stopPrank();
    }
}
