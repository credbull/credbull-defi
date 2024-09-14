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
        vm.prank(owner);
        asset = new SimpleUSDC(1_000_000 ether);

        SCALE = 10 ** asset.decimals();
        transferAndAssert(asset, owner, alice, 100_000 * SCALE);
    }

    // Scenario: Calculating returns for a standard investment
    function test__DiscountVaultTest__Daily_6APY_30day_50K() public {
        uint256 apy = 6; // APY in percentage
        uint256 tenor = 30;
        uint256 deposit = 50_000 * SCALE;
        uint256 frequencyValue = Frequencies.toValue(Frequencies.Frequency.DAYS_360);

        IDiscountVault vault = new DiscountVault(asset, apy, frequencyValue, tenor);

        // verify interest
        uint256 actualInterest = vault.calcYield(deposit, 0, tenor);
        assertEq(250 * SCALE, actualInterest, "interest not correct for $50k deposit after 30 days");

        // verify full returns
        uint256 actualShares = vault.convertToShares(deposit);
        uint256 actualReturns = vault.convertToAssetsForPeriods(actualShares, 0, tenor);
        assertEq(50_250 * SCALE, actualReturns, "principal + interest not correct for $50k deposit after 30 days");

        testVaultAtPeriods(deposit, vault, tenor);
    }

    function test__DiscountVaultTest__Monthly() public {
        uint256 apy = 12; // APY in percentage
        uint256 frequencyValue = Frequencies.toValue(Frequencies.Frequency.MONTHLY);
        uint256 tenor = 3;

        IDiscountVault vault = new DiscountVault(asset, apy, frequencyValue, tenor);

        assertEq(0, vault.convertToShares(SCALE - 1), "convert to shares not scaled");

        testVaultAtPeriods(200 * SCALE, vault, tenor);
    }

    // Scenario: Calculating returns for a rolled-over investment
    function test__DiscountVaultTest__6APY_30day_40K_and_Rollover() public {
        uint256 apy = 6; // APY in percentage
        uint256 tenor = 30;
        uint256 deposit = 50_000 * SCALE;
        uint256 frequencyValue = Frequencies.toValue(Frequencies.Frequency.DAYS_360);

        IDiscountVault vault = new DiscountVault(asset, apy, frequencyValue, tenor);

        // verify interest
        uint256 actualInterest = vault.calcYield(deposit, 0, tenor);
        assertEq(250 * SCALE, actualInterest, "interest not correct for $50k deposit after 30 days");

        // verify full returns
        uint256 actualShares = vault.convertToShares(deposit);
        uint256 actualReturns = vault.convertToAssetsForPeriods(actualShares, 0, tenor);
        assertEq(50_250 * SCALE, actualReturns, "principal + interest not correct for $50k deposit after 30 days");
    }
}
