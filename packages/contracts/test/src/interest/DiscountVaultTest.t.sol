// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IDiscountVault } from "@credbull/interest/IDiscountVault.sol";
import { DiscountVault } from "@credbull/interest/DiscountVault.sol";
import { Frequencies } from "@test/src/interest/Frequencies.t.sol";
import { CalcDiscounted } from "@credbull/interest/CalcDiscounted.sol";

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

    function test__DiscountVaultTest__CheckScale() public {
        uint256 apy = 10; // APY in percentage
        uint256 frequencyValue = Frequencies.toValue(Frequencies.Frequency.DAYS_360);
        uint256 tenor = 90;

        IDiscountVault vault = new DiscountVault(asset, apy, frequencyValue, tenor);

        uint256 scaleMinus1 = SCALE - 1;

        assertEq(0, vault.convertToShares(scaleMinus1), "convert to shares not scaled");
    }

    function test__DiscountVaultTest__Monthly() public {
        uint256 apy = 12; // APY in percentage
        uint256 frequencyValue = Frequencies.toValue(Frequencies.Frequency.MONTHLY);
        uint256 tenor = 3;

        IDiscountVault vault = new DiscountVault(asset, apy, frequencyValue, tenor);

        testVaultAtTenorPeriods(200 * SCALE, vault);
    }

    function test__DiscountVaultTest__Daily360() public {
        uint256 apy = 12; // APY in percentage
        uint256 frequencyValue = Frequencies.toValue(Frequencies.Frequency.DAYS_360);
        uint256 tenor = 30;

        IDiscountVault vault = new DiscountVault(asset, apy, frequencyValue, tenor);

        uint256 principal = 100 * SCALE;
        uint256 actualInterestDay721 = vault.calcYield(principal, 721);
        assertEq(24_033_333, actualInterestDay721, "interest should be ~ 24.0333 at day 721");

        testVaultAtTenorPeriods(principal, vault);
    }

    // Scenario: Calculating returns for a standard investment
    function test__DiscountVaultTest__6APY_30day_50K() public {
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

    function test__DiscountVaultTest__Price() public {
        uint256 apy = 12; // APY in percentage
        uint256 frequency = Frequencies.toValue(Frequencies.Frequency.DAYS_360);

        IDiscountVault vault = new DiscountVault(asset, apy, frequency, 30);

        uint256 discountScale = CalcDiscounted.SCALE;

        uint256 day0 = 0;
        assertEq(1 * discountScale, vault.calcPrice(day0)); // 1 + (0.12 * 0) / 360 = 1

        uint256 day1 = 1;
        assertEq(1_000_333_333_333_333_333, vault.calcPrice(day1)); // 1 + (0.12 * 1) / 360 ≈ 1.00033

        uint256 day30 = 30;
        assertEq((101 * discountScale / 100), vault.calcPrice(day30)); // 1 + (0.12 * 30) / 360 = 1.01
    }
}
