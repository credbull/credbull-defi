// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { LiquidContinuousMultiTokenVault } from "@credbull/yield/LiquidContinuousMultiTokenVault.sol";
import { Timer } from "@credbull/timelock/Timer.sol";
import { IMultiTokenVault } from "@credbull/token/ERC1155/IMultiTokenVault.sol";
import { TripleRateYieldStrategy } from "@credbull/yield/strategy/TripleRateYieldStrategy.sol";
import { DeployLiquidMultiTokenVault } from "@script/DeployLiquidMultiTokenVault.s.sol";

import { IMultiTokenVaultTestBase } from "@test/src/token/ERC1155/IMultiTokenVaultTestBase.t.sol";
import { Frequencies } from "@test/src/yield/Frequencies.t.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract LiquidContinuousMultiTokenVaultTest is IMultiTokenVaultTestBase {
    LiquidContinuousMultiTokenVault private _liquidVault;

    IERC20Metadata private _asset;
    uint256 private _scale;

    function setUp() public {
        DeployLiquidMultiTokenVault deployVault = new DeployLiquidMultiTokenVault();
        _liquidVault = deployVault.run(owner);

        _asset = IERC20Metadata(_liquidVault.asset());
        _scale = 10 ** _asset.decimals();

        _transferAndAssert(_asset, owner, alice, 100_000 * _scale);
    }

    function test__RequestRedeemTest__RedeemAtTenor() public {
        uint256 principal = 100 * _scale;
        testVaultAtPeriods(_liquidVault, principal, 0, _liquidVault.TENOR());
    }

    function test__LiquidContinuousVaultTest__RedeemBeforeTenor() public {
        uint256 principal = 100 * _scale;
        testVaultAtPeriods(_liquidVault, principal, 0, _liquidVault.TENOR() - 1);
    }

    function test__LiquidContinuousVaultTest__BuyAndSell() public {
        LiquidContinuousMultiTokenVault.VaultParams memory fixedApyParams = LiquidContinuousMultiTokenVault.VaultParams({
            contractOwner: owner,
            contractOperator: makeAddr("operator"),
            asset: _asset,
            yieldStrategy: new TripleRateYieldStrategy(),
            vaultStartTimestamp: block.timestamp,
            redeemNoticePeriod: 1,
            fullRateScaled: 10 * _scale,
            reducedRateScaled: 0 * _scale,
            frequency: Frequencies.toValue(Frequencies.Frequency.DAYS_360),
            tenor: 30
        });

        LiquidContinuousMultiTokenVaultMock mockVault = _createLiquidContinueMultiTokenVault(fixedApyParams);

        IMultiTokenVaultTestParams memory testParams =
            IMultiTokenVaultTestParams({ principal: 2_000 * _scale, depositPeriod: 11, redeemPeriod: 71 });

        uint256 assetStartBalance = _asset.balanceOf(alice);

        uint256 sharesAmount = testParams.principal; // 1 principal = 1 share

        // ---------------- buy (deposit) ----------------
        _warpToPeriod(mockVault, testParams.depositPeriod);

        vm.startPrank(alice);
        _asset.approve(address(mockVault), testParams.principal); // grant the vault allowance
        mockVault.executeBuy(alice, 0, testParams.principal, sharesAmount);
        vm.stopPrank();

        assertEq(
            testParams.principal,
            _asset.balanceOf(address(mockVault)),
            "vault should have the principal worth of assets"
        );
        assertEq(
            testParams.principal,
            mockVault.balanceOf(alice, testParams.depositPeriod),
            "user should have principal worth of vault shares"
        );

        // ---------------- requestSell (requestRedeem) ----------------
        _warpToPeriod(mockVault, testParams.redeemPeriod - mockVault.noticePeriod());

        // requestSell
        vm.prank(alice);
        uint256 requestId = mockVault.requestSellForDepositPeriod(sharesAmount, testParams.depositPeriod); // TODO - test should not pass in depositPeriod here
        assertEq(
            sharesAmount,
            mockVault.unlockRequested(alice, testParams.depositPeriod).amount,
            "unlockRequest should be created"
        );

        // ---------------- sell (redeem) ----------------
        uint256 expectedYield = _expectedReturns(sharesAmount, mockVault, testParams);
        assertEq(33_333333, expectedYield, "expected returns incorrect");
        vm.prank(owner);
        _transferAndAssert(_asset, owner, address(mockVault), expectedYield); // fund the vault to cover redeem

        _warpToPeriod(mockVault, testParams.redeemPeriod);

        vm.prank(alice);
        mockVault.executeSellForDepositPeriod(
            alice, testParams.depositPeriod, requestId, testParams.principal + expectedYield, sharesAmount
        );

        assertEq(0, mockVault.balanceOf(alice, testParams.depositPeriod), "user should have no shares remaining");
        assertEq(
            assetStartBalance + expectedYield,
            _asset.balanceOf(alice),
            "user should have received principal + yield back"
        );
    }

    // Scenario: Calculating returns for a standard investment
    function test__LiquidContinuousVaultTest__50k_Returns() public {
        uint256 deposit = 50_000 * _scale;

        // verify returns
        uint256 actualYield = _liquidVault.calcYield(deposit, 0, _liquidVault.TENOR());
        assertEq(416_666666, actualYield, "interest not correct for $50k deposit after 30 days");

        // verify principal + returns
        uint256 actualShares = _liquidVault.convertToShares(deposit);
        uint256 actualReturns = _liquidVault.convertToAssetsForDepositPeriod(actualShares, 0, _liquidVault.TENOR());
        assertEq(50_416_666666, actualReturns, "principal + interest not correct for $50k deposit after 30 days");

        testVaultAtPeriods(_liquidVault, deposit, 0, _liquidVault.TENOR());
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

    function _createLiquidContinueMultiTokenVault(LiquidContinuousMultiTokenVault.VaultParams memory params)
        internal
        returns (LiquidContinuousMultiTokenVaultMock _vault)
    {
        _vault = new LiquidContinuousMultiTokenVaultMock();
        _vault = LiquidContinuousMultiTokenVaultMock(
            address(new ERC1967Proxy(address(_vault), abi.encodeWithSelector(_vault.mockInitialize.selector, params)))
        );
    }
}

contract LiquidContinuousMultiTokenVaultMock is LiquidContinuousMultiTokenVault {
    constructor() {
        _disableInitializers();
    }

    function mockInitialize(VaultParams memory params) public initializer {
        super.initialize(params);
    }

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
