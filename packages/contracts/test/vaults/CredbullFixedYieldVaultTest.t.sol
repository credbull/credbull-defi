//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { HelperVaultTest } from "../base/HelperVaultTest.t.sol";
import { HelperConfig } from "../../script/HelperConfig.s.sol";
import { MockStablecoin } from "../mocks/MockStablecoin.sol";
import { CredbullFixedYieldVault } from "../../src/CredbullFixedYieldVault.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { WhitelistPlugIn } from "../../src/plugins/WhitelistPlugIn.sol";
import { CredbullKYCProvider } from "../../src/CredbullKYCProvider.sol";
import { DeployVaultFactory } from "../../script/DeployVaultFactory.s.sol";
import { CredbullKYCProvider } from "../../src/CredbullKYCProvider.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";

contract CredbullFixedYieldVaultTest is Test {
    CredbullFixedYieldVault private vault;
    HelperConfig private helperConfig;
    DeployVaultFactory private deployer;
    CredbullKYCProvider private kycProvider;

    CredbullFixedYieldVault.FixedYieldVaultParams private vaultParams;

    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");

    uint256 private precision;
    uint256 private constant INITIAL_BALANCE = 1000;
    uint256 private constant ADDITIONAL_PRECISION = 1e12;

    function setUp() public {
        deployer = new DeployVaultFactory();
        (,, kycProvider, helperConfig) = deployer.runTest();
        vaultParams = new HelperVaultTest(helperConfig.getNetworkConfig()).createFixedYieldVaultParams();
        vaultParams.kycParams.kycProvider = address(kycProvider);

        vault = new CredbullFixedYieldVault(vaultParams);

        precision = 10 ** MockStablecoin(address(vaultParams.maturityVaultParams.baseVaultParams.asset)).decimals();

        address[] memory whitelistAddresses = new address[](2);
        whitelistAddresses[0] = alice;
        whitelistAddresses[1] = bob;

        bool[] memory statuses = new bool[](2);
        statuses[0] = true;
        statuses[1] = true;

        vm.startPrank(vaultParams.contractRoles.operator);
        vault.kycProvider().updateStatus(whitelistAddresses, statuses);
        vm.stopPrank();

        MockStablecoin(address(vaultParams.maturityVaultParams.baseVaultParams.asset)).mint(
            alice, INITIAL_BALANCE * precision
        );
        MockStablecoin(address(vaultParams.maturityVaultParams.baseVaultParams.asset)).mint(
            bob, INITIAL_BALANCE * precision
        );
    }

    function test__FixedYieldVault__ShouldAllowOwnerToChangeOperator() public {
        address newOperator = makeAddr("new_operator");

        vm.startPrank(vaultParams.contractRoles.owner);
        vault.revokeRole(vault.OPERATOR_ROLE(), vaultParams.contractRoles.operator);
        vault.grantRole(vault.OPERATOR_ROLE(), newOperator);
        vm.stopPrank();

        vm.startPrank(vaultParams.contractRoles.operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                vaultParams.contractRoles.operator,
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
        vm.startPrank(vaultParams.contractRoles.owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                vaultParams.contractRoles.owner,
                vault.OPERATOR_ROLE()
            )
        );
        vault.mature();
        vm.stopPrank();
    }

    function test__FixedYieldVault__RevertMaturityToggleIfNotAdmin() public {
        vm.startPrank(vaultParams.contractRoles.operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                vaultParams.contractRoles.operator,
                vault.DEFAULT_ADMIN_ROLE()
            )
        );
        vault.toggleMaturityCheck(false);
        vm.stopPrank();

        vm.prank(vaultParams.contractRoles.owner);
        vault.toggleMaturityCheck(false);
    }

    function test__FixedYieldVault__RevertWhitelistToggleIfNotAdmin() public {
        vm.startPrank(vaultParams.contractRoles.operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                vaultParams.contractRoles.operator,
                vault.DEFAULT_ADMIN_ROLE()
            )
        );
        vault.toggleWhitelistCheck(false);
        vm.stopPrank();

        vm.prank(vaultParams.contractRoles.owner);
        vault.toggleWhitelistCheck(false);
    }

    function test__FixedYieldVault__RevertWindowToggleIfNotAdmin() public {
        vm.startPrank(vaultParams.contractRoles.operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                vaultParams.contractRoles.operator,
                vault.DEFAULT_ADMIN_ROLE()
            )
        );
        vault.toggleWindowCheck(false);
        vm.stopPrank();

        vm.prank(vaultParams.contractRoles.owner);
        vault.toggleWindowCheck(false);
    }

    function test__FixedYieldVault__ShouldCheckForWhitelsitedAddresses() public {
        address[] memory whitelistAddresses = new address[](1);
        whitelistAddresses[0] = alice;

        bool[] memory statuses = new bool[](1);
        statuses[0] = false;

        vm.startPrank(vaultParams.contractRoles.operator);
        vault.kycProvider().updateStatus(whitelistAddresses, statuses);
        vm.stopPrank();
        uint256 depositAmount = 1000 * precision;

        vm.expectRevert(
            abi.encodeWithSelector(WhitelistPlugIn.CredbullVault__NotAWhitelistedAddress.selector, alice, depositAmount)
        );
        vault.deposit(depositAmount, alice);
    }

    function test__FixedYieldVault__ExpectACallToWhitelistPlugin() public {
        address[] memory whitelistAddresses = new address[](1);
        whitelistAddresses[0] = alice;

        bool[] memory statuses = new bool[](1);
        statuses[0] = false;

        vm.startPrank(vaultParams.contractRoles.operator);
        vault.kycProvider().updateStatus(whitelistAddresses, statuses);
        vm.stopPrank();

        uint256 depositAmount = 1000 * precision;
        vm.expectRevert(
            abi.encodeWithSelector(WhitelistPlugIn.CredbullVault__NotAWhitelistedAddress.selector, alice, depositAmount)
        );
        vm.expectCall(address(vaultParams.kycParams.kycProvider), abi.encodeCall(CredbullKYCProvider.status, alice));
        vault.deposit(depositAmount, alice);
    }

    function test__FixedYieldVault__RevertMaxCapToggleIfNotAdmin() public {
        vm.startPrank(vaultParams.contractRoles.operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                vaultParams.contractRoles.operator,
                vault.DEFAULT_ADMIN_ROLE()
            )
        );
        vault.toggleMaxCapCheck(false);
        vm.stopPrank();

        vm.prank(vaultParams.contractRoles.owner);
        vault.toggleMaxCapCheck(false);
    }

    function test__FixedYieldVault__RevertUdpateMaxCapIfNotAdmin() public {
        vm.startPrank(vaultParams.contractRoles.operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                vaultParams.contractRoles.operator,
                vault.DEFAULT_ADMIN_ROLE()
            )
        );
        vault.updateMaxCap(100 * precision);
        vm.stopPrank();

        vm.prank(vaultParams.contractRoles.owner);
        vault.updateMaxCap(100 * precision);
    }

    function test__FixedYieldVault__RevertOpsIfVaultIsPaused() public {
        vm.startPrank(vaultParams.contractRoles.owner);
        vault.toggleWindowCheck(false);
        vault.pauseVault();
        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
        vault.deposit(1000 * precision, alice);
        vm.stopPrank();

        vm.startPrank(vaultParams.contractRoles.owner);
        vault.unpauseVault();
        vm.stopPrank();
    }

    function test__FixedYieldVault__ShouldAllowAdminToUnpauseVault() public {
        vm.startPrank(vaultParams.contractRoles.owner);
        vault.toggleWindowCheck(false);
        vault.pauseVault();
        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
        vault.deposit(1000 * precision, alice);
        vm.stopPrank();

        vm.startPrank(vaultParams.contractRoles.owner);
        vault.unpauseVault();
        deposit(alice, 1000 * precision, true);
        vm.stopPrank();
    }

    function test__FixedYieldVault__ShouldAllowOnlyAdminToPauseVault() public {
        vm.startPrank(vaultParams.contractRoles.operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                vaultParams.contractRoles.operator,
                vault.DEFAULT_ADMIN_ROLE()
            )
        );
        vault.pauseVault();
        vm.stopPrank();

        vm.startPrank(vaultParams.contractRoles.owner);
        vault.pauseVault();
        vm.stopPrank();
    }

    function test__FixedYieldVault__RevertWindowUpdateIfNotAdmin() public {
        vm.startPrank(vaultParams.contractRoles.operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                vaultParams.contractRoles.operator,
                vault.DEFAULT_ADMIN_ROLE()
            )
        );
        vault.updateWindow(100, 200, 300, 400);
        vm.stopPrank();

        vm.prank(vaultParams.contractRoles.owner);
        vault.updateWindow(100, 200, 300, 400);
    }

    function test__FixedYieldVault__ShouldAllowAdminToWithdrawERC20Tokens() public {
        MockStablecoin token = MockStablecoin(address(vaultParams.maturityVaultParams.baseVaultParams.asset));
        vm.prank(alice);
        token.transfer(address(vault), 100 * precision);

        assertEq(token.balanceOf(address(vault)), 100 * precision);

        vm.prank(vaultParams.contractRoles.owner);
        address[] memory addresses = new address[](1);
        addresses[0] = address(vaultParams.maturityVaultParams.baseVaultParams.asset);
        vault.withdrawERC20(addresses);

        assertEq(token.balanceOf(address(vault)), 0);
    }

    function deposit(address user, uint256 assets, bool warp) internal returns (uint256 shares) {
        // first, approve the deposit
        vm.startPrank(user);
        vaultParams.maturityVaultParams.baseVaultParams.asset.approve(address(vault), assets);
        // vaultParams.token.approve(address(vault), assets * ADDITIONAL_PRECISION);

        // wrap if set to true
        if (warp) {
            vm.warp(vaultParams.windowVaultParams.depositWindow.opensAt);
        }

        shares = vault.deposit(assets, user);
        vm.stopPrank();
    }
}
