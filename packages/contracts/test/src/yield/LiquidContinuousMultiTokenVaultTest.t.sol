// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { LiquidContinuousMultiTokenVault } from "@credbull/yield/LiquidContinuousMultiTokenVault.sol";
import { Timer } from "@credbull/timelock/Timer.sol";
import { IMultiTokenVault } from "@credbull/token/ERC1155/IMultiTokenVault.sol";
import { SimpleInterestYieldStrategy } from "@credbull/yield/strategy/SimpleInterestYieldStrategy.sol";

import { Frequencies } from "@test/src/yield/Frequencies.t.sol";

import { IMultiTokenVaultTestBase } from "@test/src/token/ERC1155/IMultiTokenVaultTestBase.t.sol";

import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract LiquidContinuousMultiTokenVaultTest is IMultiTokenVaultTestBase {
    IERC20Metadata private asset;

    uint256 internal SCALE;

    LiquidContinuousMultiTokenVault.VaultParams private FIXED_10APY_PARAMS;

    function setUp() public {
        vm.prank(owner);
        asset = new SimpleUSDC(1_000_000 ether);

        SCALE = 10 ** asset.decimals();
        _transferAndAssert(asset, owner, alice, 100_000 * SCALE);

        FIXED_10APY_PARAMS = LiquidContinuousMultiTokenVault.VaultParams({
            contractOwner: owner,
            asset: asset,
            yieldStrategy: new SimpleInterestYieldStrategy(),
            vaultStartTimestamp: block.timestamp,
            redeemNoticePeriod: 1,
            fullRateScaled: 10 * SCALE,
            reducedRateScaled: 0 * SCALE,
            frequency: Frequencies.toValue(Frequencies.Frequency.DAYS_360),
            tenor: 30
        });
    }

    function test__RequestRedeemTest__RedeemAtTenor() public {
        LiquidContinuousMultiTokenVault.VaultParams memory vaultParams = FIXED_10APY_PARAMS;

        uint256 principal = 100 * SCALE;
        LiquidContinuousMultiTokenVault vault = new LiquidContinuousMultiTokenVault(FIXED_10APY_PARAMS);

        testVaultAtPeriods(vault, principal, 0, vaultParams.tenor);
    }

    function test__LiquidContinuousVaultTest__RedeemBeforeTenor() public {
        LiquidContinuousMultiTokenVault.VaultParams memory vaultParams = FIXED_10APY_PARAMS;

        uint256 principal = 100 * SCALE;
        LiquidContinuousMultiTokenVault vault = new LiquidContinuousMultiTokenVault(FIXED_10APY_PARAMS);

        testVaultAtPeriods(vault, principal, 0, vaultParams.tenor - 1);
    }

    function test__LiquidContinuousVaultTest__BuyAndSell() public {
        LiquidContinuousMultiTokenVaultMock vault = new LiquidContinuousMultiTokenVaultMock(FIXED_10APY_PARAMS);

        IMultiTokenVaultTestParams memory testParams =
            IMultiTokenVaultTestParams({ principal: 2_000 * SCALE, depositPeriod: 11, redeemPeriod: 71 });

        uint256 assetStartBalance = asset.balanceOf(alice);

        uint256 sharesAmount = testParams.principal; // 1 principal = 1 share

        // ---------------- buy (deposit) ----------------
        _warpToPeriod(vault, testParams.depositPeriod);

        vm.startPrank(alice);
        asset.approve(address(vault), testParams.principal); // grant the vault allowance
        vault.executeBuy(alice, 0, testParams.principal, sharesAmount);
        vm.stopPrank();

        assertEq(
            testParams.principal, asset.balanceOf(address(vault)), "vault should have the principal worth of assets"
        );
        assertEq(
            testParams.principal,
            vault.balanceOf(alice, testParams.depositPeriod),
            "user should have principal worth of vault shares"
        );

        // ---------------- requestSell (requestRedeem) ----------------
        _warpToPeriod(vault, testParams.redeemPeriod - vault.noticePeriod());

        // requestSell
        vm.prank(alice);
        uint256 requestId = vault.requestSellForDepositPeriod(sharesAmount, testParams.depositPeriod); // TODO - test should not pass in depositPeriod here
        assertEq(
            sharesAmount,
            vault.unlockRequested(alice, testParams.depositPeriod).amount,
            "unlockRequest should be created"
        );

        // ---------------- sell (redeem) ----------------
        uint256 expectedYield = _expectedReturns(sharesAmount, vault, testParams);
        assertEq(33_333333, expectedYield, "expected returns incorrect");
        vm.prank(owner);
        _transferAndAssert(asset, owner, address(vault), expectedYield); // fund the vault to cover redeem

        _warpToPeriod(vault, testParams.redeemPeriod);

        vm.prank(alice);
        vault.executeSellForDepositPeriod(
            alice, testParams.depositPeriod, requestId, testParams.principal + expectedYield, sharesAmount
        );

        assertEq(0, vault.balanceOf(alice, testParams.depositPeriod), "user should have no shares remaining");
        assertEq(
            assetStartBalance + expectedYield,
            asset.balanceOf(alice),
            "user should have received principal + yield back"
        );
    }

    // Scenario: Calculating returns for a standard investment
    function test__LiquidContinuousVaultTest__Daily_6APY_30day_50K() public {
        LiquidContinuousMultiTokenVault.VaultParams memory vaultParams = LiquidContinuousMultiTokenVault.VaultParams({
            contractOwner: owner,
            asset: asset,
            yieldStrategy: new SimpleInterestYieldStrategy(),
            vaultStartTimestamp: block.timestamp,
            redeemNoticePeriod: 1,
            fullRateScaled: 6 * SCALE,
            reducedRateScaled: 0 * SCALE,
            frequency: Frequencies.toValue(Frequencies.Frequency.DAYS_360),
            tenor: 30
        });

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
        uint256 warpToTimeInSeconds = Timer(address(vault)).startTimestamp() + timePeriod * 24 hours;

        vm.warp(warpToTimeInSeconds);
    }
}

contract LiquidContinuousMultiTokenVaultMock is LiquidContinuousMultiTokenVault {
    constructor(VaultParams memory params) LiquidContinuousMultiTokenVault(params) { }

    function requestSellForDepositPeriod(uint256 amount, uint256 depositPeriod) public returns (uint256 requestId) {
        return super._requestSell(amount, depositPeriod);
    }

    function executeSellForDepositPeriod(
        address requestor,
        uint256 depositPeriod,
        uint256 requestId,
        uint256 currencyTokenAmount,
        uint256 componentTokenAmount
    ) public {
        super._executeSell(requestor, depositPeriod, requestId, currencyTokenAmount, componentTokenAmount);
    }
}
