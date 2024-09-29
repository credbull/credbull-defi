// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { LiquidContinuousMultiTokenVault } from "@credbull/yield/LiquidContinuousMultiTokenVault.sol";
import { MultiTokenVault } from "@credbull/token/ERC1155/MultiTokenVault.sol";
import { IMultiTokenVault } from "@credbull/token/ERC1155/IMultiTokenVault.sol";
import { SimpleInterestYieldStrategy } from "@credbull/yield/strategy/SimpleInterestYieldStrategy.sol";

import { Frequencies } from "@test/src/yield/Frequencies.t.sol";

import { IMultiTokenVaultTestBase } from "@test/src/token/ERC1155/IMultiTokenVaultTestBase.t.sol";

import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract LiquidContinuousMultiTokenVaultTest is IMultiTokenVaultTestBase {
    IERC20Metadata private asset;

    uint256 internal SCALE;

    function setUp() public {
        vm.prank(owner);
        asset = new SimpleUSDC(1_000_000 ether);

        SCALE = 10 ** asset.decimals();
        _transferAndAssert(asset, owner, alice, 100_000 * SCALE);
    }

    // Scenario: Calculating returns for a standard investment
    function test__LiquidContinuousVaultTest__Daily_6APY_30day_50K() public {
        uint256 deposit = 50_000 * SCALE;

        LiquidContinuousMultiTokenVault.VaultParams memory params = LiquidContinuousMultiTokenVault.VaultParams({
            asset: asset,
            yieldStrategy: new SimpleInterestYieldStrategy(),
            vaultStartTimestamp: block.timestamp,
            redeemNoticePeriod: 1,
            interestRatePercentageScaled: 6 * SCALE,
            frequency: Frequencies.toValue(Frequencies.Frequency.DAYS_360),
            tenor: 30
        });

        LiquidContinuousMultiTokenVault vault = new LiquidContinuousMultiTokenVault(params);

        // verify interest
        uint256 actualInterest = vault.calcYield(deposit, 0, params.tenor);
        assertEq(250 * SCALE, actualInterest, "interest not correct for $50k deposit after 30 days");

        // verify full returns
        uint256 actualShares = vault.convertToShares(deposit);
        uint256 actualReturns = vault.convertToAssetsForDepositPeriod(actualShares, 0, params.tenor);
        assertEq(50_250 * SCALE, actualReturns, "principal + interest not correct for $50k deposit after 30 days");

        testVaultAtPeriods(vault, deposit, 0, params.tenor);
    }

    function test__LiquidContinuousVaultTest__ShouldRevertIfRedeemBeforeTenor() public {
        LiquidContinuousMultiTokenVault.VaultParams memory params = LiquidContinuousMultiTokenVault.VaultParams({
            asset: asset,
            yieldStrategy: new SimpleInterestYieldStrategy(),
            vaultStartTimestamp: block.timestamp,
            redeemNoticePeriod: 1,
            interestRatePercentageScaled: 6 * SCALE,
            frequency: Frequencies.toValue(Frequencies.Frequency.DAYS_360),
            tenor: 30
        });

        uint256 deposit = 100 * SCALE;
        LiquidContinuousMultiTokenVault vault = new LiquidContinuousMultiTokenVault(params);
        uint256 depositPeriod = vault.currentPeriod();
        uint256 shares = vault.convertToShares(deposit);

        // check redeemPeriod > depositPeriod
        uint256 invalidRedeemPeriod = params.tenor - 1;

        // redeem before tenor - should fail
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
        LiquidContinuousMultiTokenVault liquidVault = LiquidContinuousMultiTokenVault(address(vault));

        return liquidVault.YIELD_STRATEGY().calcYield(
            address(vault), testParams.principal, testParams.depositPeriod, testParams.redeemPeriod
        );
    }

    /// @dev this assumes timePeriod is in days
    function _warpToPeriod(IMultiTokenVault vault, uint256 timePeriod) internal override {
        uint256 warpToTimeInSeconds =
            LiquidContinuousMultiTokenVault(address(vault)).startTimestamp() + timePeriod * 24 hours;

        vm.warp(warpToTimeInSeconds);
    }
}
