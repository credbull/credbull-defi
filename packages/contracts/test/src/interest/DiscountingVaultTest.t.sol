// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { DiscountingVault } from "@credbull/interest/DiscountingVault.sol";
import { Frequencies } from "@test/src/interest/Frequencies.t.sol";

import { IMultiTokenVaultTestBase } from "@test/src/interest/IMultiTokenVaultTestBase.t.sol";
import { IERC1155MintAndBurnable } from "@credbull/interest/IERC1155MintAndBurnable.sol";
import { SimpleIERC1155Mintable } from "@test/src/interest/SimpleIERC1155Mintable.t.sol";

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract DiscountingVaultTest is IMultiTokenVaultTestBase {
    using Math for uint256;

    IERC20Metadata private asset;
    IERC1155MintAndBurnable private depositLedger;

    uint256 internal SCALE;

    function setUp() public {
        vm.prank(owner);
        asset = new SimpleUSDC(1_000_000 ether);

        SCALE = 10 ** asset.decimals();
        _transferAndAssert(asset, owner, alice, 100_000 * SCALE);

        depositLedger = new SimpleIERC1155Mintable();
    }

    // Scenario: Calculating returns for a standard investment
    function test__DiscountingVaultTest__Daily_6APY_30day_50K() public {
        uint256 deposit = 50_000 * SCALE;

        DiscountingVault.DiscountingVaultParams memory params = DiscountingVault.DiscountingVaultParams({
            asset: asset,
            depositLedger: depositLedger,
            interestRatePercentage: 6,
            frequency: Frequencies.toValue(Frequencies.Frequency.DAYS_360),
            tenor: 30
        });

        DiscountingVault vault = new DiscountingVault(params);

        // verify interest
        uint256 actualInterest = vault.calcYield(deposit, 0, params.tenor);
        assertEq(250 * SCALE, actualInterest, "interest not correct for $50k deposit after 30 days");

        // verify full returns
        uint256 actualShares = vault.convertToShares(deposit);
        uint256 actualReturns = vault.convertToAssetsForDepositPeriod(actualShares, 0, params.tenor);
        assertEq(50_250 * SCALE, actualReturns, "principal + interest not correct for $50k deposit after 30 days");

        testVaultAtPeriods(deposit, vault, 0, params.tenor);
    }

    function test__DiscountingVaultTest__Monthly() public {
        DiscountingVault.DiscountingVaultParams memory params = DiscountingVault.DiscountingVaultParams({
            asset: asset,
            depositLedger: depositLedger,
            interestRatePercentage: 12,
            frequency: Frequencies.toValue(Frequencies.Frequency.MONTHLY),
            tenor: 3
        });

        DiscountingVault vault = new DiscountingVault(params);

        assertEq(0, vault.convertToShares(SCALE - 1), "convert to shares not scaled");

        testVaultAtPeriods(200 * SCALE, vault, 0, params.tenor);
    }

    // Scenario: Calculating returns for a rolled-over investment
    function test__DiscountingVaultTest__6APY_30day_40K_and_Rollover() public {
        DiscountingVault.DiscountingVaultParams memory params = DiscountingVault.DiscountingVaultParams({
            asset: asset,
            depositLedger: depositLedger,
            interestRatePercentage: 6,
            frequency: Frequencies.toValue(Frequencies.Frequency.DAYS_360),
            tenor: 30
        });

        uint256 deposit = 50_000 * SCALE;

        DiscountingVault vault = new DiscountingVault(params);

        // verify interest
        uint256 actualInterest = vault.calcYield(deposit, 0, params.tenor);
        assertEq(250 * SCALE, actualInterest, "interest not correct for $50k deposit after 30 days");

        // verify full returns
        uint256 actualShares = vault.convertToShares(deposit);
        uint256 actualReturns = vault.convertToAssetsForDepositPeriod(actualShares, 0, params.tenor);
        assertEq(50_250 * SCALE, actualReturns, "principal + interest not correct for $50k deposit after 30 days");
    }
}
