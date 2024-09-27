// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { DiscountingVault } from "@test/src/yield/DiscountingVault.t.sol";
import { MultiTokenVault } from "@credbull/token/ERC1155/MultiTokenVault.sol";
import { IMultiTokenVault } from "@credbull/token/ERC1155/IMultiTokenVault.sol";
import { IYieldStrategy } from "@credbull/yield/strategy/IYieldStrategy.sol";
import { SimpleInterestYieldStrategy } from "@credbull/yield/strategy/SimpleInterestYieldStrategy.sol";

import { Frequencies } from "@test/src/yield/Frequencies.t.sol";

import { IMultiTokenVaultTestBase } from "@test/src/token/ERC1155/IMultiTokenVaultTestBase.t.sol";

import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract DiscountingVaultTest is IMultiTokenVaultTestBase {
    IERC20Metadata private asset;
    IYieldStrategy private yieldStrategy;

    uint256 internal SCALE;

    function setUp() public {
        vm.prank(owner);
        asset = new SimpleUSDC(1_000_000 ether);

        SCALE = 10 ** asset.decimals();
        _transferAndAssert(asset, owner, alice, 100_000 * SCALE);

        yieldStrategy = new SimpleInterestYieldStrategy();
    }

    // Scenario: Calculating returns for a standard investment
    function test__DiscountingVaultTest__Daily_6APY_30day_50K() public {
        uint256 deposit = 50_000 * SCALE;

        DiscountingVault.DiscountingVaultParams memory params = DiscountingVault.DiscountingVaultParams({
            asset: asset,
            yieldStrategy: yieldStrategy,
            interestRatePercentageScaled: 6 * SCALE,
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

        testVaultAtPeriods(vault, deposit, 0, params.tenor);
    }

    function test__DiscountingVaultTest__Monthly() public {
        DiscountingVault.DiscountingVaultParams memory params = DiscountingVault.DiscountingVaultParams({
            asset: asset,
            yieldStrategy: yieldStrategy,
            interestRatePercentageScaled: 12 * SCALE,
            frequency: Frequencies.toValue(Frequencies.Frequency.MONTHLY),
            tenor: 3
        });

        DiscountingVault vault = new DiscountingVault(params);

        assertEq(0, vault.convertToShares(SCALE - 1), "convert to shares not scaled");

        testVaultAtPeriods(vault, 200 * SCALE, 0, params.tenor);
    }

    // Scenario: Calculating returns for a rolled-over investment
    function test__DiscountingVaultTest__6APY_30day_40K_and_Rollover() public {
        DiscountingVault.DiscountingVaultParams memory params = DiscountingVault.DiscountingVaultParams({
            asset: asset,
            yieldStrategy: yieldStrategy,
            interestRatePercentageScaled: 6 * SCALE,
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

    function test__DiscountingVaultTest__ShouldRevertIfRedeemBeforeTenor() public {
        DiscountingVault.DiscountingVaultParams memory params = DiscountingVault.DiscountingVaultParams({
            asset: asset,
            yieldStrategy: yieldStrategy,
            interestRatePercentageScaled: 6 * SCALE,
            frequency: Frequencies.toValue(Frequencies.Frequency.DAYS_360),
            tenor: 30
        });

        uint256 deposit = 100 * SCALE;
        DiscountingVault vault = new DiscountingVault(params);
        uint256 depositPeriod = vault.currentTimePeriodsElapsed();
        uint256 shares = vault.convertToShares(deposit);

        // check redeemPeriod > depositPeriod
        uint256 invalidRedeemPeriod = params.tenor - 1;

        // redeem before tenor - unable to derive deposit
        vm.expectRevert(
            abi.encodeWithSelector(
                MultiTokenVault.MultiTokenVault__RedeemTimePeriodNotSupported.selector,
                alice,
                depositPeriod,
                invalidRedeemPeriod
            )
        );
        vault.redeemForDepositPeriod(shares, alice, alice, depositPeriod, invalidRedeemPeriod);
    }

    function _expectedReturns(
        uint256, /* shares */
        IMultiTokenVault vault,
        IMultiTokenVaultTestParams memory testParams
    ) internal view override returns (uint256 expectedReturns_) {
        return yieldStrategy.calcYield(
            address(vault), testParams.principal, testParams.depositPeriod, testParams.redeemPeriod
        );
    }

    function _warpToPeriod(IMultiTokenVault vault, uint256 timePeriod) internal override {
        DiscountingVault(address(vault)).setCurrentTimePeriodsElapsed(timePeriod);
    }
}
