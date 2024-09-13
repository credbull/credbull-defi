// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IDiscountVault } from "@credbull/interest/IDiscountVault.sol";
import { DiscountVault } from "@credbull/interest/DiscountVault.sol";
import { Frequencies } from "@test/src/interest/Frequencies.t.sol";

import { DiscountVaultTestBase } from "./DiscountVaultTestBase.t.sol";

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract DiscountVaultTest is DiscountVaultTestBase {
    using Math for uint256;

    IERC20Metadata private asset;

    uint256 internal SCALE;

    function setUp() public {
        uint256 tokenSupply = 1_000_000 ether; // // USDC uses 6 decimals, so this is way more than 1m USDC

        vm.startPrank(owner);
        asset = new SimpleUSDC(tokenSupply);
        vm.stopPrank();

        SCALE = 10 ** asset.decimals();

        uint256 userTokenAmount = 100_000 * SCALE;

        assertEq(asset.balanceOf(owner), tokenSupply, "owner should start with total supply");
        transferAndAssert(asset, owner, alice, userTokenAmount);
        transferAndAssert(asset, owner, bob, userTokenAmount);
    }

    // Scenario: Calculating returns for a standard investment
    function test__DiscountVaultTest__Daily_6APY_30day_50K() public {
        uint256 apy = 6; // APY in percentage
        uint256 tenor = 30;
        uint256 deposit = 50_000 * SCALE; // APY in percentage
        uint256 frequencyValue = Frequencies.toValue(Frequencies.Frequency.DAYS_360);

        IDiscountVault vault = new DiscountVault(asset, apy, frequencyValue, tenor);

        // verify interest
        uint256 actualInterest = vault.calcYield(deposit, tenor);
        assertEq(250 * SCALE, actualInterest, "interest not correct for $50k deposit after 30 days");

        // verify full returns
        uint256 actualShares = vault.convertToShares(deposit);
        uint256 actualReturns = vault.convertToAssetsAtPeriod(actualShares, tenor);
        assertEq(50_250 * SCALE, actualReturns, "principal + interest not correct for $50k deposit after 30 days");

        testVaultAtTenorPeriods(deposit, vault);
    }

    function test__DiscountVaultTest__Monthly() public {
        uint256 apy = 12; // APY in percentage
        uint256 frequencyValue = Frequencies.toValue(Frequencies.Frequency.MONTHLY);
        uint256 tenor = 3;

        IDiscountVault vault = new DiscountVault(asset, apy, frequencyValue, tenor);

        assertEq(0, vault.convertToShares(SCALE - 1), "convert to shares not scaled");

        testVaultAtTenorPeriods(200 * SCALE, vault);
    }

    // Scenario: Calculating returns for a rolled-over investment
    function test__DiscountVaultTest__6APY_30day_40K_and_Rollover() public {
        uint256 apy = 6; // APY in percentage
        uint256 tenor = 30;
        uint256 deposit = 50_000 * SCALE; // APY in percentage
        uint256 frequencyValue = Frequencies.toValue(Frequencies.Frequency.DAYS_360);

        IDiscountVault vault = new DiscountVault(asset, apy, frequencyValue, tenor);

        // verify interest
        uint256 actualInterest = vault.calcYield(deposit, tenor);
        assertEq(250 * SCALE, actualInterest, "interest not correct for $50k deposit after 30 days");

        // verify full returns
        uint256 actualShares = vault.convertToShares(deposit);
        uint256 actualReturns = vault.convertToAssetsAtPeriod(actualShares, tenor);
        assertEq(50_250 * SCALE, actualReturns, "principal + interest not correct for $50k deposit after 30 days");
    }
}
