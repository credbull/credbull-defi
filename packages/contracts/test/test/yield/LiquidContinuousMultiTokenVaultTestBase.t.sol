// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { LiquidContinuousMultiTokenVault } from "@credbull/yield/LiquidContinuousMultiTokenVault.sol";
import { IYieldStrategy } from "@credbull/yield/strategy/IYieldStrategy.sol";
import { TripleRateYieldStrategy } from "@credbull/yield/strategy/TripleRateYieldStrategy.sol";
import { IMultiTokenVault } from "@credbull/token/ERC1155/IMultiTokenVault.sol";
import { IRedeemOptimizer } from "@credbull/token/ERC1155/IRedeemOptimizer.sol";
import { RedeemOptimizerFIFO } from "@credbull/token/ERC1155/RedeemOptimizerFIFO.sol";
import { DeployLiquidMultiTokenVault } from "@script/DeployLiquidMultiTokenVault.s.sol";
import { Timer } from "@credbull/timelock/Timer.sol";

import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";
import { IMultiTokenVaultTestBase } from "@test/src/token/ERC1155/IMultiTokenVaultTestBase.t.sol";

import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

abstract contract LiquidContinuousMultiTokenVaultTestBase is IMultiTokenVaultTestBase {
    LiquidContinuousMultiTokenVault internal _liquidVault;

    LiquidContinuousMultiTokenVault.VaultAuth internal _vaultAuth = LiquidContinuousMultiTokenVault.VaultAuth({
        owner: owner,
        operator: makeAddr("operator"),
        upgrader: makeAddr("upgrader")
    });

    IERC20Metadata internal _asset;
    uint256 internal _scale;

    function setUp() public {
        DeployLiquidMultiTokenVault _deployVault = new DeployLiquidMultiTokenVault();
        _liquidVault = _deployVault.run(_vaultAuth);

        _asset = IERC20Metadata(_liquidVault.asset());
        _scale = 10 ** _asset.decimals();

        _transferAndAssert(_asset, owner, alice, 1_000_000_000 * _scale);
        _transferAndAssert(_asset, owner, bob, 1_000_000_000 * _scale);
    }

    function test__LiquidContinuousMultiTokenVaultTestBase__Upgradeability() public {
        LiquidContinuousMultiTokenVaultMock vaultImpl = new LiquidContinuousMultiTokenVaultMock();
        LiquidContinuousMultiTokenVaultMock vaultProxy = LiquidContinuousMultiTokenVaultMock(
            address(
                new ERC1967Proxy(
                    address(vaultImpl),
                    abi.encodeWithSelector(vaultImpl.mockInitialize.selector, _createVaultParams(_vaultAuth))
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

        vm.prank(_vaultAuth.upgrader);
        vaultProxy.upgradeToAndCall(address(mockVaultV2), "");

        assertEq("2.0.0", mockVaultV2.version(), "version should be 2.0.0");

        assertEq(
            testParams.principal,
            vaultProxy.balanceOf(alice, testParams.depositPeriod),
            "user should have principal worth of vault shares"
        );
    }

    function test__LiquidContinuousMultiTokenVaultTestBase__Utilities() public {
        LiquidContinuousMultiTokenVault.VaultParams memory vaultParams = _createVaultParams(_vaultAuth);

        LiquidContinuousMultiTokenVault vault = new LiquidContinuousMultiTokenVault();
        vault.initialize(vaultParams);

        assertEq(Timer.CLOCK_MODE(), vault.CLOCK_MODE());
        assertEq(Timer.clock(), vault.clock());

        assertTrue(vault.getVersion() > 0, "version should be nonzero");
        assertTrue(vault.supportsInterface(type(IMultiTokenVault).interfaceId), "should support interface");
    }

    function test__LiquidContinuousMultiTokenVaultTestBase__PauseAndUnpause() public {
        IMultiTokenVaultTestParams memory testParams = IMultiTokenVaultTestParams({
            principal: 100 * _scale,
            depositPeriod: 0,
            redeemPeriod: _liquidVault.minUnlockPeriod()
        });

        vm.prank(alice);
        _asset.approve(address(_liquidVault), testParams.principal); // grant vault allowance on alice's principal

        vm.prank(owner);
        _transferAndAssert(_asset, owner, address(_liquidVault), testParams.principal); // transfer funds to cover redeem

        // ------------ paused deposit ------------
        vm.prank(_vaultAuth.operator);
        _liquidVault.pause();

        vm.prank(alice);
        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        _liquidVault.deposit(testParams.principal, alice);

        // ------------ unpaused deposit ------------
        vm.prank(_vaultAuth.operator);
        _liquidVault.unpause();

        vm.prank(alice);
        uint256 shares = _liquidVault.deposit(testParams.principal, alice);

        // ------------ paused redeem ------------
        vm.prank(_vaultAuth.operator);
        _liquidVault.pause();

        vm.prank(alice);
        _liquidVault.requestUnlock(alice, testParams.depositPeriod, shares);

        _warpToPeriod(_liquidVault, testParams.redeemPeriod);

        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        _liquidVault.redeemForDepositPeriod(shares, alice, alice, testParams.depositPeriod, testParams.redeemPeriod);

        // ------------ unpaused redeem ------------
        vm.prank(_vaultAuth.operator);
        _liquidVault.unpause();

        _liquidVault.redeemForDepositPeriod(shares, alice, alice, testParams.depositPeriod, testParams.redeemPeriod);
    }

    function test__LiquidContinuousMultiTokenVaultTestBase__SetStateVariables() public {
        TripleRateYieldStrategy newYieldStrategy = new TripleRateYieldStrategy();
        RedeemOptimizerFIFO newRedeemOptimizer = new RedeemOptimizerFIFO(0);
        uint256 newReducedRate = 50;
        uint256 newStartTimestamp = _liquidVault._vaultStartTimestamp() + 1;

        // ------------ fails with wrong operator ------------
        vm.startPrank(_vaultAuth.owner);
        vm.expectRevert();
        _liquidVault.setYieldStrategy(newYieldStrategy); // should revert due to AccessControl

        vm.expectRevert();
        _liquidVault.setRedeemOptimizer(newRedeemOptimizer); // should revert due to AccessControl

        vm.expectRevert();
        _liquidVault.setVaultStartTimestamp(newStartTimestamp); // should revert due to AccessControl

        vm.expectRevert();
        _liquidVault.setReducedRate(newReducedRate, newStartTimestamp); // should revert due to AccessControl

        vm.expectRevert();
        _liquidVault.setReducedRateAtCurrent(newReducedRate); // should revert due to AccessControl

        vm.stopPrank();

        // ------------ operator can set ------------

        vm.startPrank(_vaultAuth.operator);
        _liquidVault.setYieldStrategy(newYieldStrategy);
        assertEq(address(newYieldStrategy), address(_liquidVault._yieldStrategy()), "yield strategy not set");

        _liquidVault.setRedeemOptimizer(newRedeemOptimizer);
        assertEq(address(newRedeemOptimizer), address(_liquidVault._redeemOptimizer()), "optimizer not set");

        _liquidVault.setVaultStartTimestamp(newStartTimestamp);
        assertEq(newStartTimestamp, _liquidVault._vaultStartTimestamp(), "start timestamp not set");

        _liquidVault.setReducedRate(newReducedRate, newStartTimestamp);
        assertEq(newStartTimestamp, _liquidVault.currentPeriodRate().effectiveFromPeriod, "effective period not set");
        assertEq(newReducedRate, _liquidVault.currentPeriodRate().interestRate, "rate not set");

        vm.stopPrank();
    }

    function test__LiquidContinuousMultiTokenVaultTestBase__SetReducedRateAtCurrent() public {
        uint256 newReducedRateAtCurrent = 50;

        _warpToPeriod(_liquidVault, _liquidVault.currentPeriod() + 2);

        vm.prank(_vaultAuth.operator);
        _liquidVault.setReducedRateAtCurrent(newReducedRateAtCurrent);
        assertEq(newReducedRateAtCurrent, _liquidVault.currentPeriodRate().interestRate, "rate not set");
    }

    function test__LiquidContinuousMultiTokenVaultTestBase__ZeroAddressAuthReverts() public {
        address zeroAddress = address(0);

        LiquidContinuousMultiTokenVault liquidVault = new LiquidContinuousMultiTokenVault();
        LiquidContinuousMultiTokenVault.VaultParams memory paramsZeroOperator = _createVaultParams(
            LiquidContinuousMultiTokenVault.VaultAuth({
                owner: makeAddr("owner"),
                operator: zeroAddress,
                upgrader: makeAddr("upgrader")
            })
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                LiquidContinuousMultiTokenVault.LiquidContinuousMultiTokenVault__InvalidAuthAddress.selector,
                "operator",
                zeroAddress
            )
        );
        liquidVault.initialize(paramsZeroOperator);

        LiquidContinuousMultiTokenVault.VaultParams memory paramsZeroUpgrader = _createVaultParams(
            LiquidContinuousMultiTokenVault.VaultAuth({
                owner: makeAddr("owner"),
                operator: makeAddr("operator"),
                upgrader: zeroAddress
            })
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                LiquidContinuousMultiTokenVault.LiquidContinuousMultiTokenVault__InvalidAuthAddress.selector,
                "upgrader",
                zeroAddress
            )
        );
        liquidVault.initialize(paramsZeroUpgrader);
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

    function _createVaultParams(LiquidContinuousMultiTokenVault.VaultAuth memory vaultAuth)
        internal
        returns (LiquidContinuousMultiTokenVault.VaultParams memory vaultParams_)
    {
        DeployLiquidMultiTokenVault deployVault = new DeployLiquidMultiTokenVault();

        vm.prank(vaultAuth.owner); // prank as owner so asset has correct ownership
        IERC20Metadata asset = new SimpleUSDC(type(uint128).max);

        IYieldStrategy yieldStrategy = new TripleRateYieldStrategy();
        IRedeemOptimizer redeemOptimizer = new RedeemOptimizerFIFO(0);

        LiquidContinuousMultiTokenVault.VaultParams memory vaultParams =
            deployVault._createVaultParams(vaultAuth, asset, yieldStrategy, redeemOptimizer);

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
