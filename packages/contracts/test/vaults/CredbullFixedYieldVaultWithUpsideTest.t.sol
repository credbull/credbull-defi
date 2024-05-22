//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import { Test } from "forge-std/Test.sol";
import { HelperVaultTest } from "../base/HelperVaultTest.t.sol";
import { ICredbull } from "../../src/interface/ICredbull.sol";
import { HelperConfig } from "../../script/HelperConfig.s.sol";
import { CredbullFixedYieldVaultWithUpside } from "../../src/CredbullFixedYieldVaultWithUpside.sol";
import { MockStablecoin } from "../mocks/MockStablecoin.sol";
import { MockToken } from "../mocks/MockToken.sol";
import { DeployVaultFactory } from "../../script/DeployVaultFactory.s.sol";
import { CredbullKYCProvider } from "../../src/CredbullKYCProvider.sol";
import { console2 } from "forge-std/console2.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CredbullFixedYieldVaultWithUpsideTest is Test {
    using Math for uint256;

    CredbullFixedYieldVaultWithUpside private vault;
    HelperConfig private helperConfig;
    DeployVaultFactory private deployer;
    CredbullKYCProvider private kycProvider;

    ICredbull.FixedYieldVaultParams private vaultParams;

    address private alice = makeAddr("alice");

    uint256 private constant INITIAL_BALANCE = 1e6;
    uint256 private constant REQUIRED_COLLATERAL_PERCENTAGE = 20_00;
    uint256 private constant ADDITIONAL_PRECISION = 1e12;
    uint16 private constant MAX_PERCENTAGE = 100_00;
    IERC20 private cblToken;

    uint256 private precision;

    function setUp() public {
        deployer = new DeployVaultFactory();
        (,, kycProvider, helperConfig) = deployer.runTest();
        (vaultParams, cblToken) =
            new HelperVaultTest(helperConfig.getNetworkConfig()).createFixedYieldWithUpsideVaultParams();
        vaultParams.kycParams.kycProvider = address(kycProvider);

        vault = new CredbullFixedYieldVaultWithUpside(vaultParams, cblToken, REQUIRED_COLLATERAL_PERCENTAGE);
        precision = 10 ** MockStablecoin(address(vaultParams.baseVaultParams.asset)).decimals();

        address[] memory whitelistAddresses = new address[](1);
        whitelistAddresses[0] = alice;

        bool[] memory statuses = new bool[](1);
        statuses[0] = true;

        vm.startPrank(vaultParams.contractRoles.operator);
        vault.kycProvider().updateStatus(whitelistAddresses, statuses);
        vm.stopPrank();

        MockStablecoin(address(vaultParams.baseVaultParams.asset)).mint(alice, INITIAL_BALANCE * precision);
        MockToken(address(cblToken)).mint(alice, 200 ether);
    }

    function test__UpsideVault__DepositAssetsAndGetShares() public {
        uint256 custodiansBalance = vaultParams.baseVaultParams.asset.balanceOf(vaultParams.baseVaultParams.custodian);

        // ---- Setup Part 1, Check balance before deposit ----
        assertEq(vaultParams.baseVaultParams.asset.balanceOf(address(vault)), 0, "Vault should start with no assets");
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
            vaultParams.baseVaultParams.asset.balanceOf(vaultParams.baseVaultParams.custodian),
            depositAmount + custodiansBalance,
            "Custodian should have received the assets"
        );

        // Alice should have the shares
        assertEq(shares, depositAmount, "User should now have the Shares");
        assertEq(
            cblToken.balanceOf(address(vault)),
            (depositAmount * ADDITIONAL_PRECISION).mulDiv(REQUIRED_COLLATERAL_PERCENTAGE, MAX_PERCENTAGE),
            "Vault should now have the Tokens"
        );
        assertEq(vault.balanceOf(alice), depositAmount, "User should now have the Shares");
    }

    function test__UpsideVault__MintAssetsAndGetShares() public {
        uint256 custodiansBalance = vaultParams.baseVaultParams.asset.balanceOf(vaultParams.baseVaultParams.custodian);

        // ---- Setup Part 1, Check balance before deposit ----
        assertEq(vaultParams.baseVaultParams.asset.balanceOf(address(vault)), 0, "Vault should start with no assets");
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
            vaultParams.baseVaultParams.asset.balanceOf(vaultParams.baseVaultParams.custodian),
            sharesAmount + custodiansBalance,
            "Custodian should have received the assets"
        );

        // Alice should have the shares
        assertEq(assets, sharesAmount, "User should now have the Shares");
        assertEq(
            cblToken.balanceOf(address(vault)),
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
        MockStablecoin(address(vaultParams.baseVaultParams.asset)).mint(
            vaultParams.baseVaultParams.custodian, (100 * precision) + 1
        );
        uint256 finalBalance =
            MockStablecoin(address(vaultParams.baseVaultParams.asset)).balanceOf(vaultParams.baseVaultParams.custodian);

        vm.prank(vaultParams.baseVaultParams.custodian);
        vaultParams.baseVaultParams.asset.transfer(address(vault), finalBalance);

        // ---- Assert Vault burns shares and Alice receive asset with additional 10% ---
        uint256 balanceBeforeRedeem = vaultParams.baseVaultParams.asset.balanceOf(alice);
        vm.prank(alice);
        vault.approve(address(vault), shares);

        vm.startPrank(vaultParams.contractRoles.operator);
        vault.mature();
        vm.warp(vaultParams.windowVaultParams.matureWindow.opensAt + 1);
        vm.stopPrank();

        uint256 collateralToRedeem = vault.calculateTokenRedemption(shares, alice);

        console2.log(collateralToRedeem);

        vm.prank(alice);
        uint256 assets = vault.redeem(shares, alice, alice);

        console2.log("assets", assets);

        assertEq(cblToken.balanceOf(alice), collateralToRedeem, "Alice should now have the Tokens");
        assertEq(
            vaultParams.baseVaultParams.asset.balanceOf(alice),
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
        MockStablecoin(address(vaultParams.baseVaultParams.asset)).mint(
            vaultParams.baseVaultParams.custodian, 100 * precision
        );
        uint256 finalBalance =
            MockStablecoin(address(vaultParams.baseVaultParams.asset)).balanceOf(vaultParams.baseVaultParams.custodian);

        vm.prank(vaultParams.baseVaultParams.custodian);
        vaultParams.baseVaultParams.asset.transfer(address(vault), finalBalance);
        vm.stopPrank();

        // ---- Assert Vault burns shares and Alice receive asset with additional 10% ---
        vm.prank(alice);
        vault.approve(address(vault), shares);

        vm.startPrank(vaultParams.contractRoles.operator);
        vault.mature();
        vm.warp(vaultParams.windowVaultParams.matureWindow.opensAt + 1);
        vm.stopPrank();

        uint256 assetBalanceBeforeWithdraw = vaultParams.baseVaultParams.asset.balanceOf(alice);

        uint256 assetToReceive = vault.convertToAssets(shares);

        vm.prank(alice);
        vault.withdraw(assetToReceive, alice, alice);

        assertEq(cblToken.balanceOf(alice), 200 ether, "Alice should now have the Tokens");
        assertEq(
            vaultParams.baseVaultParams.asset.balanceOf(alice),
            assetBalanceBeforeWithdraw + assetToReceive,
            "Alice should receive finalBalance with 10% yeild"
        );
    }

    function deposit(address user, uint256 assets, bool warp) internal returns (uint256 shares) {
        // first, approve the deposit
        vm.startPrank(user);
        vaultParams.baseVaultParams.asset.approve(address(vault), assets);
        cblToken.approve(address(vault), assets * ADDITIONAL_PRECISION);

        // wrap if set to true
        if (warp) {
            vm.warp(vaultParams.windowVaultParams.depositWindow.opensAt);
        }

        shares = vault.deposit(assets, user);
        vm.stopPrank();
    }

    function mint(address user, uint256 shares, bool warp) internal returns (uint256 assets) {
        // first, approve the deposit
        vm.startPrank(user);
        vaultParams.baseVaultParams.asset.approve(address(vault), shares);
        cblToken.approve(address(vault), shares * ADDITIONAL_PRECISION);

        // wrap if set to true
        if (warp) {
            vm.warp(vaultParams.windowVaultParams.depositWindow.opensAt);
        }

        assets = vault.mint(shares, user);
        vm.stopPrank();
    }
}
