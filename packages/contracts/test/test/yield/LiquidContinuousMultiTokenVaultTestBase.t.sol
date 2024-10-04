// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { LiquidContinuousMultiTokenVault } from "@credbull/yield/LiquidContinuousMultiTokenVault.sol";
import { IYieldStrategy } from "@credbull/yield/strategy/IYieldStrategy.sol";
import { TripleRateYieldStrategy } from "@credbull/yield/strategy/TripleRateYieldStrategy.sol";
import { IMultiTokenVault } from "@credbull/token/ERC1155/IMultiTokenVault.sol";
import { IRedeemOptimizer } from "@credbull/token/ERC1155/IRedeemOptimizer.sol";
import { RedeemOptimizerFIFO } from "@credbull/token/ERC1155/RedeemOptimizerFIFO.sol";
import { DeployLiquidMultiTokenVault } from "@script/DeployLiquidMultiTokenVault.s.sol";

import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";

import { IMultiTokenVaultTestBase } from "@test/src/token/ERC1155/IMultiTokenVaultTestBase.t.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

abstract contract LiquidContinuousMultiTokenVaultTestBase is IMultiTokenVaultTestBase {
    function test__LiquidContinuousMultiTokenVaultTestBase__Upgradeability() public {
        LiquidContinuousMultiTokenVault.VaultParams memory vaultParams = _createVaultParams(owner);
        LiquidContinuousMultiTokenVaultMock vaultImpl = new LiquidContinuousMultiTokenVaultMock();
        LiquidContinuousMultiTokenVaultMock vaultProxy = LiquidContinuousMultiTokenVaultMock(
            address(
                new ERC1967Proxy(
                    address(vaultImpl), abi.encodeWithSelector(vaultImpl.mockInitialize.selector, vaultParams)
                )
            )
        );

        IERC20Metadata asset = IERC20Metadata(vaultProxy.asset());
        uint256 scale = 10 ** asset.decimals();
        _transferAndAssert(asset, owner, alice, 1_000_000_000 * scale);

        IMultiTokenVaultTestParams memory testParams =
            IMultiTokenVaultTestParams({ principal: 2_000 * scale, depositPeriod: 11, redeemPeriod: 71 });

        uint256 sharesAmount = testParams.principal; // 1 principal = 1 share
        _warpToPeriod(vaultProxy, testParams.depositPeriod);

        vm.startPrank(alice);
        asset.approve(address(vaultProxy), testParams.principal); // grant the vault allowance
        vaultProxy.executeBuy(alice, 0, testParams.principal, sharesAmount);
        vm.stopPrank();

        assertEq(
            testParams.principal,
            vaultProxy.balanceOf(alice, testParams.depositPeriod),
            "user should have principal worth of vault shares"
        );

        //Upgrade contract
        LiquidContinuousMultiTokenVaultMockV2 mockVaultV2 = new LiquidContinuousMultiTokenVaultMockV2();

        vm.prank(vaultParams.contractUpgrader);
        vaultProxy.upgradeToAndCall(address(mockVaultV2), "");

        assertEq("2.0.0", mockVaultV2.version(), "version should be 2.0.0");

        assertEq(
            testParams.principal,
            vaultProxy.balanceOf(alice, testParams.depositPeriod),
            "user should have principal worth of vault shares"
        );
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
            testParams.principal, liquidVault.lockedAmount(receiver, testParams.depositPeriod), "principal not locked"
        );

        return actualSharesAtPeriod;
    }

    function _createVaultParams(address owner_)
        internal
        returns (LiquidContinuousMultiTokenVault.VaultParams memory vaultParams_)
    {
        DeployLiquidMultiTokenVault deployVault = new DeployLiquidMultiTokenVault();

        vm.prank(owner_); // prank as owner so asset has correct ownership
        IERC20Metadata asset = new SimpleUSDC(type(uint128).max);

        IYieldStrategy yieldStrategy = new TripleRateYieldStrategy();
        IRedeemOptimizer redeemOptimizer = new RedeemOptimizerFIFO(0);

        LiquidContinuousMultiTokenVault.VaultParams memory vaultParams =
            deployVault._createVaultParams(owner_, asset, yieldStrategy, redeemOptimizer);

        return vaultParams;
    }

    // this vault requires an unlock request prior to redeeming
    function _testRedeemOnly(
        address receiver,
        IMultiTokenVault vault,
        IMultiTokenVaultTestParams memory testParams,
        uint256 sharesToRedeemAtPeriod
    ) internal virtual override returns (uint256 actualAssetsAtPeriod_) {
        LiquidContinuousMultiTokenVault liquidVault = LiquidContinuousMultiTokenVault(address(vault));

        // request unlock
        _warpToPeriod(liquidVault, testParams.redeemPeriod - liquidVault.noticePeriod());

        vm.prank(receiver);
        liquidVault.requestUnlock(receiver, testParams.depositPeriod, testParams.principal);
        assertEq(
            testParams.principal,
            liquidVault.unlockRequested(receiver, testParams.depositPeriod),
            "unlockRequest should be created"
        );

        uint256 actualAssetsAtPeriod = super._testRedeemOnly(receiver, vault, testParams, sharesToRedeemAtPeriod);

        // verify locks and request locks released
        assertEq(0, liquidVault.lockedAmount(receiver, testParams.depositPeriod), "deposit lock not released");
        assertEq(0, liquidVault.balanceOf(receiver, testParams.depositPeriod), "deposits should be redeemed");
        assertEq(0, liquidVault.unlockRequested(receiver, testParams.depositPeriod), "unlockRequest should be released");

        return actualAssetsAtPeriod;
    }

    function _expectedReturns(
        uint256, /* shares */
        IMultiTokenVault vault,
        IMultiTokenVaultTestParams memory testParams
    ) internal view override returns (uint256 expectedReturns_) {
        LiquidContinuousMultiTokenVault liquidVault = LiquidContinuousMultiTokenVault(address(vault));

        return liquidVault._yieldStrategy().calcYield(
            address(vault), testParams.principal, testParams.depositPeriod, testParams.redeemPeriod
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
