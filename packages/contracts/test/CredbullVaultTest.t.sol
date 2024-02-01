//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { HelperConfig, NetworkConfig } from "../script/HelperConfig.s.sol";
import { CredbullVault } from "../src/CredbullVault.sol";
import { console2 } from "forge-std/console2.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { MockStablecoin } from "./mocks/MockStablecoin.sol";
import { CredbullVaultFactory } from "../src/CredbullVaultFactory.sol";
import { DeployVaultFactory } from "../script/DeployVaultFactory.s.sol";
import { ICredbull } from "../src/interface/ICredbull.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

contract CredbullVaultTest is Test {
    CredbullVault private vault;
    CredbullVaultFactory private factory;
    DeployVaultFactory private deployer;
    HelperConfig private helperConfig;

    ICredbull.VaultParams private vaultParams;

    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");

    uint256 private constant INITIAL_BALANCE = 1000 ether;

    function setUp() public {
        deployer = new DeployVaultFactory();
        (factory, helperConfig) = deployer.runTest();

        (vault, vaultParams) = createTestVault();

        address[] memory whitelistAddresses = new address[](2);
        whitelistAddresses[0] = alice;
        whitelistAddresses[1] = bob;

        bool[] memory statuses = new bool[](2);
        statuses[0] = true;
        statuses[1] = true;

        CredbullVault.Rules memory rules =
            CredbullVault.Rules({ checkMaturity: true, checkVaultOpenStatus: true, checkWhitelist: true });

        vm.startPrank(vaultParams.owner);
        vault.kycProvider().updateStatus(whitelistAddresses, statuses);
        vault.setRules(rules);
        vm.stopPrank();

        MockStablecoin(address(vaultParams.asset)).mint(alice, INITIAL_BALANCE);
        MockStablecoin(address(vaultParams.asset)).mint(bob, INITIAL_BALANCE);
    }

    function test__ShareNameAndSymbol() public {
        NetworkConfig memory config = helperConfig.getNetworkConfig();
        assertEq(vault.name(), config.vaultParams.shareName);
        assertEq(vault.symbol(), config.vaultParams.shareSymbol);
    }

    function test__CustodianAddress() public {
        assertEq(vault.custodian(), vaultParams.custodian);
    }

    function test__DepositAssetsAndGetShares() public {
        uint256 custodiansBalance = vaultParams.asset.balanceOf(vaultParams.custodian);

        // ---- Setup Part 1, Check balance before deposit ----
        assertEq(vaultParams.asset.balanceOf(address(vault)), 0, "Vault should start with no assets");
        assertEq(vault.totalAssets(), 0, "Vault should start with no assets");
        assertEq(vault.balanceOf(alice), 0, "User should start with no Shares");

        // ---- Setup Part 2 - Alice Deposit and Receives shares ----
        uint256 depositAmount = 10 ether;
        //Call internal deposit function
        uint256 shares = deposit(alice, depositAmount, true);

        // ---- Assert - Vault gets the Assets, Alice gets Shares ----

        // Vault should have the assets
        assertEq(vault.totalAssets(), depositAmount, "Vault should now have the assets");
        assertEq(
            vaultParams.asset.balanceOf(vaultParams.custodian),
            depositAmount + custodiansBalance,
            "Custodian should have received the assets"
        );

        // Alice should have the shares
        assertEq(shares, depositAmount, "User should now have the Shares");
        assertEq(vault.balanceOf(alice), depositAmount, "User should now have the Shares");
    }

    function test__WithdrawAssetAndBurnShares() public {
        setRule(true, false, true);
        // ---- Setup Part 1 - Deposit Assets to the vault ---- //
        uint256 depositAmount = 10 ether;
        //Call internal deposit function
        uint256 shares = deposit(alice, depositAmount, true);

        // ----- Setup Part 2 - Deposit asset from custodian vault with 10% addition yeild ---- //
        MockStablecoin(address(vaultParams.asset)).mint(vaultParams.custodian, 1 ether);
        uint256 finalBalance = MockStablecoin(address(vaultParams.asset)).balanceOf(vaultParams.custodian);

        vm.startPrank(vaultParams.custodian);
        vaultParams.asset.approve(vaultParams.custodian, finalBalance);
        vaultParams.asset.transferFrom(vaultParams.custodian, address(vault), finalBalance);
        vm.stopPrank();

        vm.prank(vaultParams.operator);
        vault.mature();

        // ---- Assert Vault burns shares and Alice receive asset with additional 10% ---
        uint256 balanceBeforeRedeem = vaultParams.asset.balanceOf(alice);
        vm.startPrank(alice);
        vault.approve(address(vault), shares);
        uint256 assets = vault.redeem(shares, alice, alice);
        uint256 balanceAfterRedeem = vaultParams.asset.balanceOf(alice);
        vm.stopPrank();

        assertEq(balanceAfterRedeem, balanceBeforeRedeem + assets, "Alice should recieve finalBalance with 10% yeild");
    }

    function test_NotEnoughBalanceToMatureVault() public {
        // ---- Setup Part 1 - Deposit Assets to the vault ---- //
        uint256 depositAmount = 10 ether;
        deposit(alice, depositAmount, true);
        uint256 finalBalance = depositAmount;

        // ---- Transfer assets to vault ---
        vm.startPrank(vaultParams.custodian);
        vaultParams.asset.approve(vaultParams.custodian, finalBalance);
        vaultParams.asset.transferFrom(vaultParams.custodian, address(vault), finalBalance);
        vm.stopPrank();

        // ---- Assert it can't be matured yet ---
        vm.prank(vaultParams.operator);
        vm.expectRevert(CredbullVault.CredbullVault__NotEnoughBalanceToMature.selector);
        vault.mature();
    }

    function test__RevertOnWithdrawIfVaultNotMatured() public {
        // ---- Setup Part 1 - Deposit Assets to the vault ---- //
        uint256 depositAmount = 10 ether;
        //Call internal deposit function
        uint256 shares = deposit(alice, depositAmount, true);

        vm.startPrank(alice);
        vault.approve(address(vault), shares);

        vm.warp(vaultParams.redemptionOpensAt);

        vm.expectRevert(CredbullVault.CredbullVault__NotMatured.selector);
        vault.redeem(shares, alice, alice);
        vm.stopPrank();
    }

    function test__RevertDepositIfReceiverNotWhitelisted() public {
        address[] memory whitelistAddresses = new address[](1);
        whitelistAddresses[0] = alice;

        bool[] memory statuses = new bool[](1);
        statuses[0] = false;

        vm.startPrank(vaultParams.owner);
        vault.kycProvider().updateStatus(whitelistAddresses, statuses);
        vm.stopPrank();

        vm.expectRevert(CredbullVault.CredbullVault__NotAWhitelistedAddress.selector);
        vm.warp(vaultParams.depositOpensAt);
        vault.deposit(10 ether, alice);
    }

    function test__deposit_should_fail_if_the_vault_deposit_window_is_in_the_future() public {
        // given that the vault's deposit window is in the future
        // when Alice try to deposit 10 ether
        // then the deposit should be reverted
        vm.expectRevert(
            abi.encodeWithSelector(
                CredbullVault.CredbullVault__OperationOutsideRequiredWindow.selector,
                "deposit",
                vaultParams.depositOpensAt,
                vaultParams.depositClosesAt,
                block.timestamp
            )
        );
        vault.deposit(10 ether, alice);
    }

    function test_deposit_succeeds_when_the_vault_deposit_window_is_open() public {
        // given that we are in the vault's deposit window
        // when Alice try to deposit 10 ether
        // then the deposit should be reverted
        deposit(alice, 10 ether, true);
        assertEq(vault.balanceOf(alice), 10 ether);
    }

    function test__deposit_should_fail_if_the_vault_deposit_window_is_in_the_past() public {
        // given that the vault's deposit window is in the past
        vm.warp(vaultParams.depositClosesAt + 1);

        // when Alice try to deposit 10 ether
        // then the deposit should be reverted
        vm.startPrank(alice);
        vaultParams.asset.approve(address(vault), 10 ether);
        vm.expectRevert(
            abi.encodeWithSelector(
                CredbullVault.CredbullVault__OperationOutsideRequiredWindow.selector,
                "deposit",
                vaultParams.depositOpensAt,
                vaultParams.depositClosesAt,
                block.timestamp
            )
        );
        vault.deposit(10 ether, alice);
        vm.stopPrank();
    }

    function test__withdraw_should_fail_if_the_vault_redemption_window_is_in_the_future() public {
        setRule(false, true, true);
        uint256 shares = deposit(alice, 10 ether, true);
        vm.startPrank(alice);
        // given that the vault's redemption window is in the future
        // when Alice try to redeem 10 ether
        // then the redemption should be reverted
        vm.expectRevert(
            abi.encodeWithSelector(
                CredbullVault.CredbullVault__OperationOutsideRequiredWindow.selector,
                "withdraw",
                vaultParams.redemptionOpensAt,
                vaultParams.redemptionClosesAt,
                block.timestamp
            )
        );
        vault.redeem(shares, alice, alice);
        vm.stopPrank();
    }

    function test__withdraw_should_succeed_if_between_the_vault_redemption_window() public {
        setRule(false, true, true);
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

    function test__withdraw_should_fail_if_the_vault_redemption_window_is_in_the_past() public {
        setRule(false, true, true);
        uint256 shares = deposit(alice, 10 ether, true);
        vm.startPrank(alice);

        // given that the vault's redemption window is in the past
        vm.warp(vaultParams.redemptionClosesAt + 1);

        // when Alice try to redeem 10 ether
        // then the redemption should be reverted
        vm.expectRevert(
            abi.encodeWithSelector(
                CredbullVault.CredbullVault__OperationOutsideRequiredWindow.selector,
                "withdraw",
                vaultParams.redemptionOpensAt,
                vaultParams.redemptionClosesAt,
                block.timestamp
            )
        );
        vault.redeem(shares, alice, alice);
        vm.stopPrank();
    }

    function test__ShouldNotRevertOnWhitelistModifier() public {
        address[] memory whitelistAddresses = new address[](1);
        whitelistAddresses[0] = alice;

        bool[] memory statuses = new bool[](1);
        statuses[0] = false;

        vm.startPrank(vaultParams.owner);
        vault.kycProvider().updateStatus(whitelistAddresses, statuses);
        vm.stopPrank();

        setRule(true, true, false);
        deposit(alice, 10 ether, true);
        assertEq(vault.balanceOf(alice), 10 ether);
    }

    function test__ShouldNotRevertOnMaturityModifier() public {
        setRule(false, false, true);

        uint256 depositAmount = 10 ether;
        uint256 shares = deposit(alice, depositAmount, true);

        vm.prank(vaultParams.custodian);
        vaultParams.asset.transfer(address(vault), depositAmount);

        vm.startPrank(alice);
        vault.approve(address(vault), shares);

        vault.redeem(shares, alice, alice);
        assertEq(vaultParams.asset.balanceOf(alice), INITIAL_BALANCE);
        vm.stopPrank();
    }

    function test__ShouldAllowOnlyOperatorToMatureVault() public {
        vm.startPrank(vaultParams.owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, vaultParams.owner, factory.OPERATOR_ROLE()
            )
        );
        vault.mature();
        vm.stopPrank();
    }

    function test__ShouldAllowOwnerToChangeOperator() public {
        address newOperator = makeAddr("new_operator");

        vm.startPrank(vaultParams.owner);
        vault.revokeRole(vault.OPERATOR_ROLE(), vaultParams.operator);
        vault.grantRole(vault.OPERATOR_ROLE(), newOperator);
        vm.stopPrank();

        vm.startPrank(vaultParams.operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, vaultParams.operator, vault.OPERATOR_ROLE()
            )
        );
        vault.mature();
        vm.stopPrank();

        vm.startPrank(newOperator);
        vault.mature();
        vm.stopPrank();
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

    function setRule(bool maturity, bool vaultOpen, bool whitelist)
        internal
        returns (CredbullVault.Rules memory rules)
    {
        rules =
            CredbullVault.Rules({ checkMaturity: maturity, checkVaultOpenStatus: vaultOpen, checkWhitelist: whitelist });

        vm.prank(vaultParams.owner);
        vault.setRules(rules);
    }

    function createTestVault() internal returns (CredbullVault, ICredbull.VaultParams memory) {
        NetworkConfig memory config = helperConfig.getNetworkConfig();
        ICredbull.VaultParams memory params = config.vaultParams;

        vm.prank(config.factoryParams.operator);
        return (factory.createVault(params), params);
    }
}
