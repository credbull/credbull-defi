//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import { Test } from "forge-std/Test.sol";
import { ICredbull } from "../../src/interface/ICredbull.sol";
import { NetworkConfig, HelperConfig } from "../../script/HelperConfig.s.sol";
import { CredbullFixedYieldVaultWithUpside } from "../../src/CredbullFixedYieldVaultWithUpside.sol";
import { MockStablecoin } from "../mocks/MockStablecoin.sol";
import { MockToken } from "../mocks/MockToken.sol";
import { console2 } from "forge-std/console2.sol";

contract CredbullFixedYieldVaultWithUpsideTest is Test {
    using Math for uint256;

    CredbullFixedYieldVaultWithUpside private vault;
    HelperConfig private helperConfig;

    ICredbull.VaultParams private vaultParams;

    address private alice = makeAddr("alice");

    uint256 private constant INITIAL_BALANCE = 1e6;
    uint256 private constant REQUIRED_COLLATERAL_PERCENTAGE = 20_00;
    uint256 private constant ADDITIONAL_PRECISION = 1e12;
    uint16 private constant MAX_PERCENTAGE = 100_00;

    uint256 private precision;

    function setUp() public {
        helperConfig = new HelperConfig(true);
        NetworkConfig memory config = helperConfig.getNetworkConfig();
        vaultParams = config.vaultParams;
        vault = new CredbullFixedYieldVaultWithUpside(vaultParams, vaultParams.token, REQUIRED_COLLATERAL_PERCENTAGE);
        precision = 10 ** MockStablecoin(address(vaultParams.asset)).decimals();

        address[] memory whitelistAddresses = new address[](1);
        whitelistAddresses[0] = alice;

        bool[] memory statuses = new bool[](1);
        statuses[0] = true;

        vm.startPrank(vaultParams.owner);
        vault.kycProvider().updateStatus(whitelistAddresses, statuses);
        vm.stopPrank();

        MockStablecoin(address(vaultParams.asset)).mint(alice, INITIAL_BALANCE * precision);
        MockToken(address(vaultParams.token)).mint(alice, 200 ether);
    }

    function test__UpsideVault__DepositAssetsAndGetShares() public {
        uint256 custodiansBalance = vaultParams.asset.balanceOf(vaultParams.custodian);

        // ---- Setup Part 1, Check balance before deposit ----
        assertEq(vaultParams.asset.balanceOf(address(vault)), 0, "Vault should start with no assets");
        assertEq(vault.totalAssets(), 0, "Vault should start with no assets");
        assertEq(vault.balanceOf(alice), 0, "User should start with no Shares");

        // ---- Setup Part 2 - Alice Deposit and Receives shares ----
        uint256 depositAmount = 1000 * precision;
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
        assertEq(
            vaultParams.token.balanceOf(address(vault)),
            (depositAmount * ADDITIONAL_PRECISION).mulDiv(REQUIRED_COLLATERAL_PERCENTAGE, MAX_PERCENTAGE),
            "Vault should now have the Tokens"
        );
        assertEq(vault.balanceOf(alice), depositAmount, "User should now have the Shares");
    }

    function test__UpsideVault__MintAssetsAndGetShares() public {
        uint256 custodiansBalance = vaultParams.asset.balanceOf(vaultParams.custodian);

        // ---- Setup Part 1, Check balance before deposit ----
        assertEq(vaultParams.asset.balanceOf(address(vault)), 0, "Vault should start with no assets");
        assertEq(vault.totalAssets(), 0, "Vault should start with no assets");
        assertEq(vault.balanceOf(alice), 0, "User should start with no Shares");

        // ---- Setup Part 2 - Alice Deposit and Receives shares ----
        uint256 sharesAmount = 1000 * precision;
        //Call internal deposit function
        uint256 assets = mint(alice, sharesAmount, true);

        // ---- Assert - Vault gets the Assets, Alice gets Shares ----

        // Vault should have the assets
        assertEq(vault.totalAssets(), sharesAmount, "Vault should now have the assets");
        assertEq(
            vaultParams.asset.balanceOf(vaultParams.custodian),
            sharesAmount + custodiansBalance,
            "Custodian should have received the assets"
        );

        // Alice should have the shares
        assertEq(assets, sharesAmount, "User should now have the Shares");
        assertEq(
            vaultParams.token.balanceOf(address(vault)),
            (sharesAmount * ADDITIONAL_PRECISION).mulDiv(REQUIRED_COLLATERAL_PERCENTAGE, MAX_PERCENTAGE),
            "Vault should now have the Tokens"
        );
        assertEq(vault.balanceOf(alice), sharesAmount, "User should now have the Shares");
    }

    function test__UpsideVault__RedeemAssetAndBurnShares() public {
        // ---- Setup Part 1 - Deposit Assets to the vault ---- //
        uint256 depositAmount = 1000 * precision;
        //Call internal deposit function
        uint256 shares = deposit(alice, depositAmount, true);

        // ----- Setup Part 2 - Deposit asset from custodian vault with 10% addition yeild ---- //
        MockStablecoin(address(vaultParams.asset)).mint(vaultParams.custodian, (100 * precision) + 1);
        uint256 finalBalance = MockStablecoin(address(vaultParams.asset)).balanceOf(vaultParams.custodian);

        vm.prank(vaultParams.custodian);
        vaultParams.asset.transfer(address(vault), finalBalance);

        // ---- Assert Vault burns shares and Alice receive asset with additional 10% ---
        uint256 balanceBeforeRedeem = vaultParams.asset.balanceOf(alice);
        vm.prank(alice);
        vault.approve(address(vault), shares);

        vm.startPrank(vaultParams.operator);
        vault.mature();
        vm.warp(vaultParams.redemptionOpensAt + 1);
        vm.stopPrank();

        uint256 collateralToRedeem = vault.calculateTokenRedemption(shares, alice);
        console2.log(vault.getCollateralAmount(depositAmount));
        console2.log(vault.totalCollateralDeposited());
        console2.log(collateralToRedeem);

        vm.prank(alice);
        uint256 assets = vault.redeem(shares, alice, alice);

        assertEq(vaultParams.token.balanceOf(alice), collateralToRedeem, "Alice should now have the Tokens");
        assertEq(
            vaultParams.asset.balanceOf(alice),
            balanceBeforeRedeem + assets,
            "Alice should receive finalBalance with 10% yeild"
        );
    }

    function test__UpsideVault__WithdrawAssetAndBurnShares() public {
        // ---- Setup Part 1 - Deposit Assets to the vault ---- //
        uint256 depositAmount = 1000 * precision;
        //Call internal deposit function
        uint256 shares = deposit(alice, depositAmount, true);

        // ----- Setup Part 2 - Deposit asset from custodian vault with 10% addition yeild ---- //
        MockStablecoin(address(vaultParams.asset)).mint(vaultParams.custodian, 100 * precision);
        uint256 finalBalance = MockStablecoin(address(vaultParams.asset)).balanceOf(vaultParams.custodian);

        vm.prank(vaultParams.custodian);
        vaultParams.asset.transfer(address(vault), finalBalance);
        vm.stopPrank();

        // ---- Assert Vault burns shares and Alice receive asset with additional 10% ---
        vm.prank(alice);
        vault.approve(address(vault), shares);

        vm.startPrank(vaultParams.operator);
        vault.mature();
        vm.warp(vaultParams.redemptionOpensAt + 1);
        vm.stopPrank();

        uint256 assetBalanceBeforeWithdraw = vaultParams.asset.balanceOf(alice);

        uint256 assetToReceive = vault.convertToAssets(shares);

        vm.prank(alice);
        vault.withdraw(assetToReceive, alice, alice);

        assertEq(vaultParams.token.balanceOf(alice), 200 ether, "Alice should now have the Tokens");
        assertEq(
            vaultParams.asset.balanceOf(alice),
            assetBalanceBeforeWithdraw + assetToReceive,
            "Alice should receive finalBalance with 10% yeild"
        );
    }

    function deposit(address user, uint256 assets, bool warp) internal returns (uint256 shares) {
        // first, approve the deposit
        vm.startPrank(user);
        vaultParams.asset.approve(address(vault), assets);
        vaultParams.token.approve(address(vault), assets * ADDITIONAL_PRECISION);

        // wrap if set to true
        if (warp) {
            vm.warp(vaultParams.depositOpensAt);
        }

        shares = vault.deposit(assets, alice);
        vm.stopPrank();
    }

    function mint(address user, uint256 shares, bool warp) internal returns (uint256 assets) {
        // first, approve the deposit
        vm.startPrank(user);
        vaultParams.asset.approve(address(vault), shares);
        vaultParams.token.approve(address(vault), shares * ADDITIONAL_PRECISION);

        // wrap if set to true
        if (warp) {
            vm.warp(vaultParams.depositOpensAt);
        }

        assets = vault.mint(shares, alice);
        vm.stopPrank();
    }
}
