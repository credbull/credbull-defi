//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";

import { Test } from "forge-std/Test.sol";

import { HelperConfig } from "@script/HelperConfig.s.sol";
import { DeployVaultFactory } from "@script/DeployVaultFactory.s.sol";

import { CredbullFixedYieldVault } from "@credbull/CredbullFixedYieldVault.sol";
import { CredbullWhiteListProvider } from "@credbull/CredbullWhiteListProvider.sol";
import { WhiteListProvider } from "@credbull/provider/whiteList/WhiteListProvider.sol";
import { WhiteListPlugin } from "@credbull/plugin/WhiteListPlugin.sol";
import { FixedYieldVault } from "@credbull/vault/FixedYieldVault.sol";
import { Vault } from "@credbull/vault/Vault.sol";

import { ParamsFactory } from "@test/test/vault/utils/ParamsFactory.t.sol";
import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CredbullFixedYieldVaultTest is Test {
    CredbullFixedYieldVault private vault;
    HelperConfig private helperConfig;
    DeployVaultFactory private deployer;
    CredbullWhiteListProvider private whiteListProvider;

    CredbullFixedYieldVault.FixedYieldVaultParams private params;

    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");

    uint256 private precision;
    uint256 private constant INITIAL_BALANCE = 1000;
    uint256 private constant ADDITIONAL_PRECISION = 1e12;

    function setUp() public {
        deployer = new DeployVaultFactory();
        (,, whiteListProvider, helperConfig) = deployer.runTest();
        params = new ParamsFactory(helperConfig.getNetworkConfig()).createFixedYieldVaultParams();
        params.whiteListPlugin.whiteListProvider = address(whiteListProvider);

        vault = new CredbullFixedYieldVault(params);

        precision = 10 ** SimpleUSDC(address(params.maturityVault.vault.asset)).decimals();

        address[] memory whiteListAddresses = new address[](2);
        whiteListAddresses[0] = alice;
        whiteListAddresses[1] = bob;

        bool[] memory statuses = new bool[](2);
        statuses[0] = true;
        statuses[1] = true;

        vm.startPrank(params.roles.operator);
        vault.WHITELIST_PROVIDER().updateStatus(whiteListAddresses, statuses);
        vm.stopPrank();

        SimpleUSDC(address(params.maturityVault.vault.asset)).mint(alice, INITIAL_BALANCE * precision);
        SimpleUSDC(address(params.maturityVault.vault.asset)).mint(bob, INITIAL_BALANCE * precision);
    }

    function test__FixedYieldVault__RevertOnInvalidAddress() public {
        params.roles.owner = address(0);
        vm.expectRevert(abi.encodeWithSelector(FixedYieldVault.FixedYieldVault__InvalidOwnerAddress.selector));
        new CredbullFixedYieldVault(params);

        params.roles.owner = makeAddr("owner");
        params.roles.operator = address(0);
        vm.expectRevert(abi.encodeWithSelector(FixedYieldVault.FixedYieldVault__InvalidOperatorAddress.selector));
        new CredbullFixedYieldVault(params);
    }

    function test__FixedYieldVault__ShouldAllowOwnerToChangeOperator() public {
        address newOperator = makeAddr("new_operator");

        vm.startPrank(params.roles.owner);
        vault.revokeRole(vault.OPERATOR_ROLE(), params.roles.operator);
        vault.grantRole(vault.OPERATOR_ROLE(), newOperator);
        vm.stopPrank();

        vm.startPrank(params.roles.operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, params.roles.operator, vault.OPERATOR_ROLE()
            )
        );
        vault.mature();
        vm.stopPrank();

        vm.startPrank(newOperator);
        vault.mature();
        vm.stopPrank();
    }

    function test__FixedYieldVault__RevertMatureIfNotOperator() public {
        vm.startPrank(params.roles.owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, params.roles.owner, vault.OPERATOR_ROLE()
            )
        );
        vault.mature();
        vm.stopPrank();
    }

    function test__FixedYieldVault__ExpectedAssetOnMaturity() public {
        uint256 depositAmount = 10 * precision;
        deposit(alice, depositAmount, false);

        uint256 expectedAssetValue = ((depositAmount * (100_000 + params.promisedYield)) / 100_000);
        assertEq(vault.expectedAssetsOnMaturity(), expectedAssetValue);
    }

    function test__FixedYieldVault__ExpectedAssetOnMaturityZeroFixedYield() public {
        params.promisedYield = 0; // zero fixed yield

        CredbullFixedYieldVault zeroFixedYieldVault = new CredbullFixedYieldVault(params);

        uint256 depositAmount = 10 * precision;
        deposit(zeroFixedYieldVault, alice, depositAmount, false);

        uint256 expectedAssetValue = depositAmount;
        assertEq(zeroFixedYieldVault.expectedAssetsOnMaturity(), expectedAssetValue);
    }

    function test__FixedYieldVault__RevertMaturityToggleIfNotAdmin() public {
        bool previousMaturityStatus = vault.checkMaturity();
        vm.startPrank(params.roles.operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                params.roles.operator,
                vault.DEFAULT_ADMIN_ROLE()
            )
        );
        vault.setMaturityCheck(!previousMaturityStatus);
        vm.stopPrank();

        vm.prank(params.roles.owner);
        vault.setMaturityCheck(!previousMaturityStatus);
    }

    function test__FixedYieldVault__RevertWhiteListToggleIfNotAdmin() public {
        vm.startPrank(params.roles.operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                params.roles.operator,
                vault.DEFAULT_ADMIN_ROLE()
            )
        );
        vault.toggleWhiteListCheck();
        vm.stopPrank();

        vm.prank(params.roles.owner);
        vault.toggleWhiteListCheck();
    }

    function test__FixedYieldVault__RevertWindowToggleIfNotAdmin() public {
        vm.startPrank(params.roles.operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                params.roles.operator,
                vault.DEFAULT_ADMIN_ROLE()
            )
        );
        vault.toggleWindowCheck();
        vm.stopPrank();

        vm.prank(params.roles.owner);
        vault.toggleWindowCheck();
    }

    function test__FixedYieldVault__ShouldCheckForWhiteListedAddresses() public {
        address[] memory whiteListAddresses = new address[](1);
        whiteListAddresses[0] = alice;

        bool[] memory statuses = new bool[](1);
        statuses[0] = false;

        vm.startPrank(params.roles.operator);
        vault.WHITELIST_PROVIDER().updateStatus(whiteListAddresses, statuses);
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

        vm.startPrank(params.roles.operator);
        vault.WHITELIST_PROVIDER().updateStatus(whiteListAddresses, statuses);
        vm.stopPrank();

        uint256 depositAmount = 1000 * precision;
        vm.expectRevert(
            abi.encodeWithSelector(WhiteListPlugin.CredbullVault__NotWhiteListed.selector, alice, depositAmount)
        );
        vm.expectCall(
            address(params.whiteListPlugin.whiteListProvider), abi.encodeCall(WhiteListProvider.status, alice)
        );
        vault.deposit(depositAmount, alice);
    }

    function test__FixedYieldVault__RevertMaxCapToggleIfNotAdmin() public {
        bool previousStatus = vault.checkMaxCap();
        vm.startPrank(params.roles.operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                params.roles.operator,
                vault.DEFAULT_ADMIN_ROLE()
            )
        );
        vault.setCheckMaxCap(!previousStatus);
        vm.stopPrank();

        vm.prank(params.roles.owner);
        vault.setCheckMaxCap(!previousStatus);
    }

    function test__FixedYieldVault__RevertUdpateMaxCapIfNotAdmin() public {
        vm.startPrank(params.roles.operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                params.roles.operator,
                vault.DEFAULT_ADMIN_ROLE()
            )
        );
        vault.updateMaxCap(100 * precision);
        vm.stopPrank();

        vm.prank(params.roles.owner);
        vault.updateMaxCap(100 * precision);
    }

    function test__FixedYieldVault__RevertOpsIfVaultIsPaused() public {
        vm.startPrank(params.roles.owner);
        vault.toggleWindowCheck();
        vault.pauseVault();
        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
        vault.deposit(1000 * precision, alice);
        vm.stopPrank();

        vm.startPrank(params.roles.owner);
        vault.unpauseVault();
        vm.stopPrank();
    }

    function test__FixedYieldVault__ShouldAllowAdminToUnpauseVault() public {
        vm.startPrank(params.roles.owner);
        vault.toggleWindowCheck();
        vault.pauseVault();
        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
        vault.deposit(1000 * precision, alice);
        vm.stopPrank();

        vm.startPrank(params.roles.owner);
        vault.unpauseVault();
        deposit(alice, 1000 * precision, true);
        vm.stopPrank();
    }

    function test__FixedYieldVault__ShouldAllowOnlyAdminToPauseVault() public {
        vm.startPrank(params.roles.operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                params.roles.operator,
                vault.DEFAULT_ADMIN_ROLE()
            )
        );
        vault.pauseVault();
        vm.stopPrank();

        vm.startPrank(params.roles.owner);
        vault.pauseVault();
        vm.stopPrank();
    }

    function test__FixedYieldVault__RevertWindowUpdateIfNotAdmin() public {
        vm.startPrank(params.roles.operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                params.roles.operator,
                vault.DEFAULT_ADMIN_ROLE()
            )
        );
        vault.updateWindow(100, 200, 300, 400);
        vm.stopPrank();

        vm.prank(params.roles.owner);
        vault.updateWindow(100, 200, 300, 400);
    }

    function test__FixedYieldVault__ShouldAllowAdminToWithdrawERC20Tokens() public {
        SimpleUSDC token = SimpleUSDC(address(params.maturityVault.vault.asset));
        vm.prank(alice);
        token.transfer(address(vault), 100 * precision);

        assertEq(token.balanceOf(address(vault)), 100 * precision);

        vm.prank(params.roles.owner);
        address[] memory addresses = new address[](1);
        addresses[0] = address(params.maturityVault.vault.asset);
        vault.withdrawERC20(addresses);

        assertEq(token.balanceOf(address(vault)), 0);
    }

    function test__FixedYieldVault__DepositAssetsAndGetShares() public {
        IERC20 asset = IERC20(vault.asset());
        uint256 custodiansBalance = asset.balanceOf(vault.CUSTODIAN());

        address vaultAddress = address(vault);
        // address receiver = makeAddr("receiver");
        address receiver = vaultAddress;

        // ---- Setup Part 1, Check balance before deposit ----
        assertEq(asset.balanceOf(address(vault)), 0, "Vault should start with no assets");
        assertEq(vault.totalAssets(), 0, "Vault should start with no assets");
        assertEq(vault.balanceOf(alice), 0, "User should start with no Shares");

        // ---- Setup Part 2 - alice Deposit and receiver receives shares ----
        uint256 depositAmount = 10 * precision;
        //Call internal deposit function
        uint256 shares = deposit(vault, alice, receiver, depositAmount, false);

        // ---- Assert - Vault gets the Assets, Receiver gets Shares ----

        // vault should have the assets
        assertEq(vault.totalAssets(), depositAmount, "Vault should now have the assets");
        assertEq(
            asset.balanceOf(vault.CUSTODIAN()),
            depositAmount + custodiansBalance,
            "Custodian should have received the assets"
        );

        // receiver should have the shares
        assertEq(shares, depositAmount, "User should now have the Shares");
        assertEq(vault.balanceOf(receiver), depositAmount, "Receiver should now have the Shares");
        assertEq(vault.balanceOf(vaultAddress), depositAmount, "Vault should now have the Shares");

        address[] memory addresses = new address[](1);
        addresses[0] = address(vault);

        vm.prank(params.roles.owner);
        vm.expectRevert(abi.encodeWithSelector(Vault.CredbullVault__TransferOutsideEcosystem.selector, address(vault)));
        vault.withdrawERC20(addresses);
    }

    function deposit(address user, uint256 assets, bool warp) internal returns (uint256 shares) {
        return deposit(vault, user, assets, warp);
    }

    function deposit(CredbullFixedYieldVault fixedYieldVault, address user, uint256 assets, bool warp)
        internal
        returns (uint256 shares)
    {
        return deposit(fixedYieldVault, user, user, assets, warp);
    }

    function deposit(
        CredbullFixedYieldVault fixedYieldVault,
        address owner,
        address receiver,
        uint256 assets,
        bool warp
    ) internal returns (uint256 shares) {
        // first, approve the deposit
        vm.startPrank(owner);
        params.maturityVault.vault.asset.approve(address(fixedYieldVault), assets);

        // wrap if set to true
        if (warp) {
            vm.warp(params.windowPlugin.depositWindow.opensAt);
        }

        shares = fixedYieldVault.deposit(assets, receiver);
        vm.stopPrank();
    }
}
