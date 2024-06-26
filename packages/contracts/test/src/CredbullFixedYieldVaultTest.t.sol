//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";

import { Test } from "forge-std/Test.sol";

import { HelperConfig } from "@script/HelperConfig.s.sol";
import { DeployVaultFactory } from "@script/DeployVaultFactory.s.sol";

import { CredbullFixedYieldVault } from "@credbull/CredbullFixedYieldVault.sol";
import { CredbullWhiteListProvider } from "@credbull/CredbullWhiteListProvider.sol";
import { WhiteListProvider } from "@credbull/provider/whiteList/WhiteListProvider.sol";
import { WhiteListPlugin } from "@credbull/plugin/WhiteListPlugin.sol";

import { ParamsFactory } from "@test/test/vault/utils/ParamsFactory.t.sol";
import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";

contract CredbullFixedYieldVaultTest is Test {
    CredbullFixedYieldVault private vault;
    HelperConfig private helperConfig;
    DeployVaultFactory private deployer;
    CredbullWhiteListProvider private whiteListProvider;

    CredbullFixedYieldVault.FixedYieldVaultParameters private vaultParams;

    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");

    uint256 private precision;
    uint256 private constant INITIAL_BALANCE = 1000;
    uint256 private constant ADDITIONAL_PRECISION = 1e12;

    function setUp() public {
        deployer = new DeployVaultFactory();
        (,, whiteListProvider, helperConfig) = deployer.runTest();
        vaultParams = new ParamsFactory(helperConfig.getNetworkConfig()).createFixedYieldVaultParams();
        vaultParams.whiteListPlugin.whiteListProvider = address(whiteListProvider);

        vault = new CredbullFixedYieldVault(vaultParams);

        precision = 10 ** SimpleUSDC(address(vaultParams.maturityVault.vault.asset)).decimals();

        address[] memory whiteListAddresses = new address[](2);
        whiteListAddresses[0] = alice;
        whiteListAddresses[1] = bob;

        bool[] memory statuses = new bool[](2);
        statuses[0] = true;
        statuses[1] = true;

        vm.startPrank(vaultParams.roles.operator);
        vault.whiteListProvider().updateStatus(whiteListAddresses, statuses);
        vm.stopPrank();

        SimpleUSDC(address(vaultParams.maturityVault.vault.asset)).mint(alice, INITIAL_BALANCE * precision);
        SimpleUSDC(address(vaultParams.maturityVault.vault.asset)).mint(bob, INITIAL_BALANCE * precision);
    }

    function test__FixedYieldVault__ShouldAllowOwnerToChangeOperator() public {
        address newOperator = makeAddr("new_operator");

        vm.startPrank(vaultParams.roles.owner);
        vault.revokeRole(vault.OPERATOR_ROLE(), vaultParams.roles.operator);
        vault.grantRole(vault.OPERATOR_ROLE(), newOperator);
        vm.stopPrank();

        vm.startPrank(vaultParams.roles.operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                vaultParams.roles.operator,
                vault.OPERATOR_ROLE()
            )
        );
        vault.mature();
        vm.stopPrank();

        vm.startPrank(newOperator);
        vault.mature();
        vm.stopPrank();
    }

    function test__FixedYieldVault__RevertMatureIfNotOperator() public {
        vm.startPrank(vaultParams.roles.owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, vaultParams.roles.owner, vault.OPERATOR_ROLE()
            )
        );
        vault.mature();
        vm.stopPrank();
    }

    function test__FixedYieldVault__RevertMaturityToggleIfNotAdmin() public {
        vm.startPrank(vaultParams.roles.operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                vaultParams.roles.operator,
                vault.DEFAULT_ADMIN_ROLE()
            )
        );
        vault.toggleMaturityCheck(false);
        vm.stopPrank();

        vm.prank(vaultParams.roles.owner);
        vault.toggleMaturityCheck(false);
    }

    function test__FixedYieldVault__RevertWhiteListToggleIfNotAdmin() public {
        vm.startPrank(vaultParams.roles.operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                vaultParams.roles.operator,
                vault.DEFAULT_ADMIN_ROLE()
            )
        );
        vault.toggleWhiteListCheck(false);
        vm.stopPrank();

        vm.prank(vaultParams.roles.owner);
        vault.toggleWhiteListCheck(false);
    }

    function test__FixedYieldVault__RevertWindowToggleIfNotAdmin() public {
        vm.startPrank(vaultParams.roles.operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                vaultParams.roles.operator,
                vault.DEFAULT_ADMIN_ROLE()
            )
        );
        vault.toggleWindowCheck(false);
        vm.stopPrank();

        vm.prank(vaultParams.roles.owner);
        vault.toggleWindowCheck(false);
    }

    function test__FixedYieldVault__ShouldCheckForWhitelsitedAddresses() public {
        address[] memory whiteListAddresses = new address[](1);
        whiteListAddresses[0] = alice;

        bool[] memory statuses = new bool[](1);
        statuses[0] = false;

        vm.startPrank(vaultParams.roles.operator);
        vault.whiteListProvider().updateStatus(whiteListAddresses, statuses);
        vm.stopPrank();
        uint256 depositAmount = 1000 * precision;

        vm.expectRevert(
            abi.encodeWithSelector(WhiteListPlugin.CredbullVault__NotWhiteListed.selector, alice, depositAmount)
        );
        vault.deposit(depositAmount, alice);
    }

    function test__FixedYieldVault__ExpectACallToWhiteListPlugin() public {
        address[] memory whiteListAddresses = new address[](1);
        whiteListAddresses[0] = alice;

        bool[] memory statuses = new bool[](1);
        statuses[0] = false;

        vm.startPrank(vaultParams.roles.operator);
        vault.whiteListProvider().updateStatus(whiteListAddresses, statuses);
        vm.stopPrank();

        uint256 depositAmount = 1000 * precision;
        vm.expectRevert(
            abi.encodeWithSelector(WhiteListPlugin.CredbullVault__NotWhiteListed.selector, alice, depositAmount)
        );
        vm.expectCall(
            address(vaultParams.whiteListPlugin.whiteListProvider), abi.encodeCall(WhiteListProvider.status, alice)
        );
        vault.deposit(depositAmount, alice);
    }

    function test__FixedYieldVault__RevertMaxCapToggleIfNotAdmin() public {
        vm.startPrank(vaultParams.roles.operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                vaultParams.roles.operator,
                vault.DEFAULT_ADMIN_ROLE()
            )
        );
        vault.toggleMaxCapCheck(false);
        vm.stopPrank();

        vm.prank(vaultParams.roles.owner);
        vault.toggleMaxCapCheck(false);
    }

    function test__FixedYieldVault__RevertUdpateMaxCapIfNotAdmin() public {
        vm.startPrank(vaultParams.roles.operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                vaultParams.roles.operator,
                vault.DEFAULT_ADMIN_ROLE()
            )
        );
        vault.updateMaxCap(100 * precision);
        vm.stopPrank();

        vm.prank(vaultParams.roles.owner);
        vault.updateMaxCap(100 * precision);
    }

    function test__FixedYieldVault__RevertOpsIfVaultIsPaused() public {
        vm.startPrank(vaultParams.roles.owner);
        vault.toggleWindowCheck(false);
        vault.pauseVault();
        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
        vault.deposit(1000 * precision, alice);
        vm.stopPrank();

        vm.startPrank(vaultParams.roles.owner);
        vault.unpauseVault();
        vm.stopPrank();
    }

    function test__FixedYieldVault__ShouldAllowAdminToUnpauseVault() public {
        vm.startPrank(vaultParams.roles.owner);
        vault.toggleWindowCheck(false);
        vault.pauseVault();
        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
        vault.deposit(1000 * precision, alice);
        vm.stopPrank();

        vm.startPrank(vaultParams.roles.owner);
        vault.unpauseVault();
        deposit(alice, 1000 * precision, true);
        vm.stopPrank();
    }

    function test__FixedYieldVault__ShouldAllowOnlyAdminToPauseVault() public {
        vm.startPrank(vaultParams.roles.operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                vaultParams.roles.operator,
                vault.DEFAULT_ADMIN_ROLE()
            )
        );
        vault.pauseVault();
        vm.stopPrank();

        vm.startPrank(vaultParams.roles.owner);
        vault.pauseVault();
        vm.stopPrank();
    }

    function test__FixedYieldVault__RevertWindowUpdateIfNotAdmin() public {
        vm.startPrank(vaultParams.roles.operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                vaultParams.roles.operator,
                vault.DEFAULT_ADMIN_ROLE()
            )
        );
        vault.updateWindow(100, 200, 300, 400);
        vm.stopPrank();

        vm.prank(vaultParams.roles.owner);
        vault.updateWindow(100, 200, 300, 400);
    }

    function test__FixedYieldVault__ShouldAllowAdminToWithdrawERC20Tokens() public {
        SimpleUSDC token = SimpleUSDC(address(vaultParams.maturityVault.vault.asset));
        vm.prank(alice);
        token.transfer(address(vault), 100 * precision);

        assertEq(token.balanceOf(address(vault)), 100 * precision);

        vm.prank(vaultParams.roles.owner);
        address[] memory addresses = new address[](1);
        addresses[0] = address(vaultParams.maturityVault.vault.asset);
        vault.withdrawERC20(addresses);

        assertEq(token.balanceOf(address(vault)), 0);
    }

    function deposit(address user, uint256 assets, bool warp) internal returns (uint256 shares) {
        // first, approve the deposit
        vm.startPrank(user);
        vaultParams.maturityVault.vault.asset.approve(address(vault), assets);
        // vaultParams.token.approve(address(vault), assets * ADDITIONAL_PRECISION);

        // wrap if set to true
        if (warp) {
            vm.warp(vaultParams.windowPlugin.depositWindow.opensAt);
        }

        shares = vault.deposit(assets, user);
        vm.stopPrank();
    }
}
