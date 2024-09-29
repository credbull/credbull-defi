// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { LiquidContinuousMultiTokenVault } from "@credbull/yield/LiquidContinuousMultiTokenVault.sol";
import { IMultiTokenVault } from "@credbull/token/ERC1155/IMultiTokenVault.sol";
import { SimpleInterestYieldStrategy } from "@credbull/yield/strategy/SimpleInterestYieldStrategy.sol";

import { Frequencies } from "@test/src/yield/Frequencies.t.sol";

import { IMultiTokenVaultTestBase } from "@test/src/token/ERC1155/IMultiTokenVaultTestBase.t.sol";

import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract LiquidContinuousMultiTokenVaultTest is IMultiTokenVaultTestBase {
    IERC20Metadata private asset;

    uint256 internal SCALE;

    LiquidContinuousMultiTokenVault.VaultParams private DAILY_6APY_PARAMS;

    function setUp() public {
        vm.prank(owner);
        asset = new SimpleUSDC(1_000_000 ether);

        SCALE = 10 ** asset.decimals();
        _transferAndAssert(asset, owner, alice, 100_000 * SCALE);

        DAILY_6APY_PARAMS = LiquidContinuousMultiTokenVault.VaultParams({
            asset: asset,
            yieldStrategy: new SimpleInterestYieldStrategy(),
            vaultStartTimestamp: block.timestamp,
            redeemNoticePeriod: 1,
            interestRatePercentageScaled: 6 * SCALE,
            frequency: Frequencies.toValue(Frequencies.Frequency.DAYS_360),
            tenor: 30
        });
    }

    function test__RequestRedeemTest__RedeemPrincipalAtTenor() public {
        LiquidContinuousMultiTokenVault.VaultParams memory vaultParams = DAILY_6APY_PARAMS;

        uint256 deposit = 100 * SCALE;
        LiquidContinuousMultiTokenVault vault = new LiquidContinuousMultiTokenVault(DAILY_6APY_PARAMS);

        testVaultAtPeriods(vault, deposit, 0, vaultParams.tenor);
    }

    function test__LiquidContinuousVaultTest__RedeemPrincipalBeforeTenor() public {
        LiquidContinuousMultiTokenVault.VaultParams memory vaultParams = DAILY_6APY_PARAMS;

        uint256 deposit = 100 * SCALE;
        LiquidContinuousMultiTokenVault vault = new LiquidContinuousMultiTokenVault(DAILY_6APY_PARAMS);

        testVaultAtPeriods(vault, deposit, 0, vaultParams.tenor - 1);
    }

    function test__RequestRedeemTest__RedeemYield() public {
        uint256 depositPeriod = 1;
        uint256 principal = 101 * SCALE;

        LiquidContinuousMultiTokenVault liquidVault = new LiquidContinuousMultiTokenVault(DAILY_6APY_PARAMS);
        uint256 redeemPeriod = depositPeriod + liquidVault.noticePeriod();

        IMultiTokenVaultTestParams memory testParams = _createTestParams(principal, 1, redeemPeriod);

        // ------------------- deposit -------------------
        uint256 shares = _testDepositOnly(alice, liquidVault, testParams);
        uint256 prevUserAssetBalance = asset.balanceOf(alice);

        // ------------------- request unlock -------------------
        uint256 expectedYield = _expectedReturns(shares, liquidVault, testParams);

        // request unlock
        vm.prank(alice);
        liquidVault.requestUnlock(alice, testParams.depositPeriod, redeemPeriod, expectedYield);

        // ------------------- redeem Yield -------------------
        _warpToPeriod(liquidVault, redeemPeriod); // warp ahead

        // now redeem
        vm.startPrank(alice);
        liquidVault.redeemYieldOnly(alice, alice, testParams.depositPeriod, redeemPeriod, principal);
        vm.stopPrank();

        // principal should be moved to the redeemPeriod
        assertEq(0, liquidVault.lockedAmount(alice, depositPeriod), "principal should be released at deposit period");
        assertEq(
            testParams.principal,
            liquidVault.lockedAmount(alice, redeemPeriod),
            "principal should be locked at redeem period"
        );
        assertEq(
            0, liquidVault.unlockRequested(alice, testParams.depositPeriod).amount, "unlockRequest should be released"
        );
        assertEq(prevUserAssetBalance + expectedYield, asset.balanceOf(alice), "user should have received the yield");
    }

    // Scenario: Calculating returns for a standard investment
    function test__LiquidContinuousVaultTest__Daily_6APY_30day_50K() public {
        LiquidContinuousMultiTokenVault.VaultParams memory vaultParams = DAILY_6APY_PARAMS;
        uint256 deposit = 50_000 * SCALE;

        LiquidContinuousMultiTokenVault vault = new LiquidContinuousMultiTokenVault(vaultParams);

        // verify interest
        uint256 actualInterest = vault.calcYield(deposit, 0, vaultParams.tenor);
        assertEq(250 * SCALE, actualInterest, "interest not correct for $50k deposit after 30 days");

        // verify full returns
        uint256 actualShares = vault.convertToShares(deposit);
        uint256 actualReturns = vault.convertToAssetsForDepositPeriod(actualShares, 0, vaultParams.tenor);
        assertEq(50_250 * SCALE, actualReturns, "principal + interest not correct for $50k deposit after 30 days");

        testVaultAtPeriods(vault, deposit, 0, vaultParams.tenor);
    }

    // verify deposit.  updates vault assets and shares.
    function _testDepositOnly(address receiver, IMultiTokenVault vault, IMultiTokenVaultTestParams memory testParams)
    internal
    virtual
    override
    returns (uint256 actualSharesAtPeriod_)
    {
        uint256 actualSharesAtPeriod = super._testDepositOnly(receiver, vault, testParams);

        assertEq(
            actualSharesAtPeriod,
            vault.balanceOf(receiver, testParams.depositPeriod),
            _assertMsg(
                "!!! receiver did not receive the correct vault shares - balanceOf ", vault, testParams.depositPeriod
            )
        );

        LiquidContinuousMultiTokenVault liquidVault = LiquidContinuousMultiTokenVault(address(vault));

        assertEq(
            testParams.principal, liquidVault.lockedAmount(alice, testParams.depositPeriod), "principal not locked"
        );

        return actualSharesAtPeriod;
    }

    // this vault requires an unlock request prior to redeeming
    function _testRedeemOnly(
        address receiver,
        IMultiTokenVault vault,
        IMultiTokenVaultTestParams memory testParams,
        uint256 sharesToRedeemAtPeriod,
        uint256 prevReceiverAssetBalance // assetBalance before redeeming the latest deposit
    ) internal virtual override returns (uint256 actualAssetsAtPeriod_) {
        LiquidContinuousMultiTokenVault liquidVault = LiquidContinuousMultiTokenVault(address(vault));

        // request unlock
        vm.prank(alice);
        liquidVault.requestUnlock(alice, testParams.depositPeriod, testParams.redeemPeriod, testParams.principal);
        assertEq(
            testParams.principal,
            liquidVault.unlockRequested(alice, testParams.depositPeriod).amount,
            "unlockRequest should be created"
        );

        uint256 actualAssetsAtPeriod =
                            super._testRedeemOnly(receiver, vault, testParams, sharesToRedeemAtPeriod, prevReceiverAssetBalance);

        // verify locks and request locks released
        assertEq(0, liquidVault.lockedAmount(alice, testParams.depositPeriod), "deposit lock not released");
        assertEq(0, liquidVault.balanceOf(alice, testParams.depositPeriod), "deposits should be redeemed");
        assertEq(
            0, liquidVault.unlockRequested(alice, testParams.depositPeriod).amount, "unlockRequest should be released"
        );

        return actualAssetsAtPeriod;
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
