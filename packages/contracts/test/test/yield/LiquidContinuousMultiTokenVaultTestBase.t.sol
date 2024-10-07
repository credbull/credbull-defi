// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { LiquidContinuousMultiTokenVault } from "@credbull/yield/LiquidContinuousMultiTokenVault.sol";
import { IYieldStrategy } from "@credbull/yield/strategy/IYieldStrategy.sol";
import { TripleRateYieldStrategy } from "@credbull/yield/strategy/TripleRateYieldStrategy.sol";
import { IMultiTokenVault } from "@credbull/token/ERC1155/IMultiTokenVault.sol";
import { IRedeemOptimizer } from "@credbull/token/ERC1155/IRedeemOptimizer.sol";
import { RedeemOptimizerFIFO } from "@credbull/token/ERC1155/RedeemOptimizerFIFO.sol";
import { DeployLiquidMultiTokenVault } from "@script/DeployLiquidMultiTokenVault.s.sol";

import { IMultiTokenVaultTestBase } from "@test/test/token/ERC1155/IMultiTokenVaultTestBase.t.sol";
import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

abstract contract LiquidContinuousMultiTokenVaultTestBase is IMultiTokenVaultTestBase {
    LiquidContinuousMultiTokenVault internal _liquidVault;

    LiquidContinuousMultiTokenVault.VaultAuth internal _vaultAuth = LiquidContinuousMultiTokenVault.VaultAuth({
        owner: makeAddr("owner"),
        operator: makeAddr("operator"),
        upgrader: makeAddr("upgrader")
    });

    IERC20Metadata internal _asset;
    uint256 internal _scale;

    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");

    function setUp() public {
        DeployLiquidMultiTokenVault _deployVault = new DeployLiquidMultiTokenVault();
        _liquidVault = _deployVault.run(_vaultAuth);

        _asset = IERC20Metadata(_liquidVault.asset());
        _scale = 10 ** _asset.decimals();

        _transferAndAssert(_asset, _vaultAuth.owner, alice, 100_000 * _scale);
        _transferAndAssert(_asset, _vaultAuth.owner, bob, 100_000 * _scale);
    }

    // verify deposit.  updates vault assets and shares.
    function _testDepositOnly(address receiver, IMultiTokenVault vault, TestParam memory testParam)
        internal
        virtual
        override
        returns (uint256 actualSharesAtPeriod_)
    {
        uint256 actualSharesAtPeriod = super._testDepositOnly(receiver, vault, testParam);

        assertEq(
            actualSharesAtPeriod,
            vault.balanceOf(receiver, testParam.depositPeriod),
            _assertMsg(
                "!!! receiver did not receive the correct vault shares - balanceOf ", vault, testParam.depositPeriod
            )
        );

        LiquidContinuousMultiTokenVault liquidVault = LiquidContinuousMultiTokenVault(address(vault));

        assertEq(
            testParam.principal, liquidVault.lockedAmount(receiver, testParam.depositPeriod), "principal not locked"
        );

        return actualSharesAtPeriod;
    }

    function _createVaultParams(LiquidContinuousMultiTokenVault.VaultAuth memory vaultAuth)
        internal
        returns (LiquidContinuousMultiTokenVault.VaultParams memory vaultParams_)
    {
        DeployLiquidMultiTokenVault deployVault = new DeployLiquidMultiTokenVault();

        IERC20Metadata asset = new SimpleUSDC(vaultAuth.owner, type(uint128).max);
        IYieldStrategy yieldStrategy = new TripleRateYieldStrategy();
        IRedeemOptimizer redeemOptimizer = new RedeemOptimizerFIFO(IRedeemOptimizer.OptimizerBasis.Shares, 0);

        LiquidContinuousMultiTokenVault.VaultParams memory vaultParams =
            deployVault._createVaultParams(vaultAuth, asset, yieldStrategy, redeemOptimizer);

        return vaultParams;
    }

    // this vault requires an unlock request prior to redeeming
    function _testRedeemOnly(
        address receiver,
        IMultiTokenVault vault,
        TestParam memory testParam,
        uint256 sharesToRedeemAtPeriod
    ) internal virtual override returns (uint256 actualAssetsAtPeriod_) {
        LiquidContinuousMultiTokenVault liquidVault = LiquidContinuousMultiTokenVault(address(vault));

        // request unlock
        _warpToPeriod(liquidVault, testParam.redeemPeriod - liquidVault.noticePeriod());

        vm.prank(receiver);
        liquidVault.requestUnlock(receiver, testParam.depositPeriod, testParam.principal);
        assertEq(
            testParam.principal,
            liquidVault.unlockRequested(receiver, testParam.depositPeriod),
            "unlockRequest should be created"
        );

        uint256 actualAssetsAtPeriod = super._testRedeemOnly(receiver, vault, testParam, sharesToRedeemAtPeriod);

        // verify locks and request locks released
        assertEq(0, liquidVault.lockedAmount(receiver, testParam.depositPeriod), "deposit lock not released");
        assertEq(0, liquidVault.balanceOf(receiver, testParam.depositPeriod), "deposits should be redeemed");
        assertEq(0, liquidVault.unlockRequested(receiver, testParam.depositPeriod), "unlockRequest should be released");

        return actualAssetsAtPeriod;
    }

    function _expectedReturns(uint256, /* shares */ IMultiTokenVault vault, TestParam memory testParam)
        internal
        view
        override
        returns (uint256 expectedReturns_)
    {
        LiquidContinuousMultiTokenVault liquidVault = LiquidContinuousMultiTokenVault(address(vault));

        return liquidVault._yieldStrategy().calcYield(
            address(vault), testParam.principal, testParam.depositPeriod, testParam.redeemPeriod
        );
    }

    /// @dev this assumes timePeriod is in days
    function _warpToPeriod(IMultiTokenVault vault, uint256 timePeriod) internal override {
        LiquidContinuousMultiTokenVault liquidVault = LiquidContinuousMultiTokenVault(address(vault));

        uint256 warpToTimeInSeconds = liquidVault._vaultStartTimestamp() + timePeriod * 24 hours;

        vm.warp(warpToTimeInSeconds);
    }
}

contract LiquidContinuousMultiTokenVaultMock is LiquidContinuousMultiTokenVault {
    constructor() {
        _disableInitializers();
    }

    function mockInitialize(VaultParams memory params) public initializer {
        super.initialize(params);
    }
}

contract LiquidContinuousMultiTokenVaultMockV2 is LiquidContinuousMultiTokenVaultMock {
    function version() public pure returns (string memory) {
        return "2.0.0";
    }
}
