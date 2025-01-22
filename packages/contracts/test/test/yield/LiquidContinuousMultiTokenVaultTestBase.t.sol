// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { LiquidContinuousMultiTokenVault } from "@credbull/yield/LiquidContinuousMultiTokenVault.sol";
import { IYieldStrategy } from "@credbull/yield/strategy/IYieldStrategy.sol";
import { TripleRateYieldStrategy } from "@credbull/yield/strategy/TripleRateYieldStrategy.sol";
import { IVault } from "@credbull/token/ERC4626/IVault.sol";
import { IMultiTokenVault } from "@credbull/token/ERC1155/IMultiTokenVault.sol";
import { IRedeemOptimizer } from "@credbull/token/ERC1155/IRedeemOptimizer.sol";
import { RedeemOptimizerFIFO } from "@credbull/token/ERC1155/RedeemOptimizerFIFO.sol";
import { Timer } from "@credbull/timelock/Timer.sol";

import { DeployLiquidMultiTokenVault } from "@script/DeployLiquidMultiTokenVault.s.sol";
import { IMultiTokenVaultTestBase } from "@test/test/token/ERC1155/IMultiTokenVaultTestBase.t.sol";
import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";
import { TestParamSet } from "@test/test/token/ERC1155/TestParamSet.t.sol";

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

abstract contract LiquidContinuousMultiTokenVaultTestBase is IMultiTokenVaultTestBase {
    using TestParamSet for TestParamSet.TestParam[];

    LiquidContinuousMultiTokenVault internal _liquidVault;

    LiquidContinuousMultiTokenVault.VaultAuth internal _vaultAuth = LiquidContinuousMultiTokenVault.VaultAuth({
        owner: makeAddr("owner"),
        operator: makeAddr("operator"),
        upgrader: makeAddr("upgrader"),
        assetManager: makeAddr("assetManager")
    });

    IERC20Metadata internal _asset;
    uint256 internal _scale;

    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");

    function setUp() public virtual {
        DeployLiquidMultiTokenVault _deployVault = new DeployLiquidMultiTokenVault();
        _liquidVault = _deployVault.run(_vaultAuth);

        // warp to a "real time" time rather than block.timestamp=1
        vm.warp(_liquidVault._vaultStartTimestamp() + 1);

        _asset = IERC20Metadata(_liquidVault.asset());
        _scale = 10 ** _asset.decimals();

        _transferAndAssert(_asset, _vaultAuth.owner, alice, 100_000 * _scale);
        _transferAndAssert(_asset, _vaultAuth.owner, bob, 100_000 * _scale);
    }

    // verify deposit.  updates vault assets and shares.
    function _testDepositOnly(
        TestParamSet.TestUsers memory testUsers,
        IVault vault,
        TestParamSet.TestParam memory testParam
    ) internal virtual override returns (uint256 actualSharesAtPeriod_) {
        LiquidContinuousMultiTokenVault liquidVault = LiquidContinuousMultiTokenVault(address(vault));

        uint256 prevVaultBalanceOf = _asset.balanceOf(address(_liquidVault));
        uint256 prevVaultPeriodsElapsed = vault.currentPeriodsElapsed();

        _warpToPeriod(vault, testParam.depositPeriod); // warp to deposit period to calc totalAssets correctly
        uint256 prevVaultTotalAssets = liquidVault.totalAssets();
        _warpToPeriod(vault, prevVaultPeriodsElapsed); // restore previous period state

        uint256 actualSharesAtPeriod = super._testDepositOnly(testUsers, vault, testParam);

        assertEq(
            actualSharesAtPeriod,
            liquidVault.balanceOf(testUsers.tokenReceiver, testParam.depositPeriod),
            _assertMsg(
                "!!! receiver did not receive the correct vault shares - balanceOf ", vault, testParam.depositPeriod
            )
        );

        assertEq(
            prevVaultBalanceOf + testParam.principal,
            _asset.balanceOf(address(_liquidVault)),
            "vault didn't receive the assets"
        );

        assertEq(
            testParam.principal,
            liquidVault.lockedAmount(testUsers.tokenReceiver, testParam.depositPeriod),
            "principal not locked"
        );

        _warpToPeriod(vault, testParam.depositPeriod); // warp to deposit period to calc totalAssets correctly
        assertEq(
            prevVaultTotalAssets + testParam.principal, liquidVault.totalAssets(), "vault total assets not updated"
        );
        _warpToPeriod(vault, prevVaultPeriodsElapsed); // restore previous period state

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

    function _testRedeemOnly(
        TestParamSet.TestUsers memory redeemUsers,
        IVault vault,
        TestParamSet.TestParam memory testParam,
        uint256 sharesToRedeemAtPeriod
    ) internal virtual override returns (uint256 actualAssetsAtPeriod_) {
        LiquidContinuousMultiTokenVault liquidVault = LiquidContinuousMultiTokenVault(address(vault));

        uint256 prevLockedAmount = liquidVault.lockedAmount(redeemUsers.tokenOwner, testParam.depositPeriod);
        uint256 prevBalanceOf = liquidVault.balanceOf(redeemUsers.tokenOwner, testParam.depositPeriod);

        // request unlock
        _warpToPeriod(liquidVault, testParam.redeemPeriod - liquidVault.noticePeriod());

        vm.prank(redeemUsers.tokenOwner);
        liquidVault.setApprovalForAll(redeemUsers.tokenOperator, true);

        // this vault requires an unlock/redeem request prior to redeeming
        vm.prank(redeemUsers.tokenOperator);
        liquidVault.requestRedeem(sharesToRedeemAtPeriod, redeemUsers.tokenOperator, redeemUsers.tokenOwner);

        vm.prank(redeemUsers.tokenOwner);
        liquidVault.setApprovalForAll(redeemUsers.tokenOperator, false);

        assertEq(
            sharesToRedeemAtPeriod,
            liquidVault.unlockRequestAmountByDepositPeriod(redeemUsers.tokenOwner, testParam.depositPeriod),
            "unlockRequest should be created"
        );

        uint256 actualAssetsAtPeriod = super._testRedeemOnly(redeemUsers, vault, testParam, sharesToRedeemAtPeriod);

        // verify locks and request locks released
        assertEq(
            prevLockedAmount - sharesToRedeemAtPeriod,
            liquidVault.lockedAmount(redeemUsers.tokenOwner, testParam.depositPeriod),
            "deposit lock not released"
        );
        assertEq(
            prevBalanceOf - sharesToRedeemAtPeriod,
            liquidVault.balanceOf(redeemUsers.tokenOwner, testParam.depositPeriod),
            "deposits should be redeemed"
        );
        assertEq(
            0,
            liquidVault.unlockRequestAmountByDepositPeriod(redeemUsers.tokenOwner, testParam.depositPeriod),
            "unlockRequest should be released"
        );

        return actualAssetsAtPeriod;
    }

    /// @dev - requestRedeem over multiple deposit and principals into one requestRedeemPeriod
    function _testRequestRedeemMultiDeposit(
        TestParamSet.TestUsers memory redeemUsers,
        LiquidContinuousMultiTokenVault liquidVault,
        TestParamSet.TestParam[] memory depositTestParams,
        uint256 redeemPeriod // we are testing multiple deposits into one redeemPeriod
    ) internal virtual {
        _warpToPeriod(_liquidVault, redeemPeriod - liquidVault.noticePeriod());

        uint256 sharesToRedeem = depositTestParams.totalPrincipal();

        vm.prank(redeemUsers.tokenOwner);
        liquidVault.setApprovalForAll(redeemUsers.tokenOperator, true);

        vm.prank(redeemUsers.tokenOperator);
        uint256 requestId = liquidVault.requestRedeem(sharesToRedeem, redeemUsers.tokenOperator, redeemUsers.tokenOwner);

        vm.prank(redeemUsers.tokenOwner);
        liquidVault.setApprovalForAll(redeemUsers.tokenOperator, false);

        (uint256[] memory unlockDepositPeriods, uint256[] memory unlockShares) =
            liquidVault.unlockRequests(redeemUsers.tokenOwner, requestId);

        (uint256[] memory expectedDepositPeriods, uint256[] memory expectedShares) = depositTestParams.deposits();

        assertEq(expectedDepositPeriods, unlockDepositPeriods, "deposit periods mismatch for requestRedeem");
        assertEq(expectedShares, unlockShares, "shares mismatch for requestRedeem");
    }

    /// @dev - redeem ONLY (no requestRedeem) over multiple deposit and principals into one requestRedeemPeriod
    function _testRedeemAfterRequestRedeemMultiDeposit(
        TestParamSet.TestUsers memory redeemUsers,
        IMultiTokenVault vault,
        TestParamSet.TestParam[] memory depositTestParams,
        uint256 redeemPeriod // we are testing multiple deposits into one redeemPeriod
    ) internal virtual returns (uint256 assets_) {
        LiquidContinuousMultiTokenVault liquidVault = LiquidContinuousMultiTokenVault(address(vault));

        uint256 assets = super._testRedeemMultiDeposit(redeemUsers, vault, depositTestParams, redeemPeriod);

        // verify the requestRedeems are released
        (uint256[] memory unlockDepositPeriods, uint256[] memory unlockAmounts) =
            liquidVault.unlockRequests(redeemUsers.tokenOwner, redeemPeriod);
        assertEq(0, unlockDepositPeriods.length, "unlock should be released");
        assertEq(0, unlockAmounts.length, "unlock should be released");

        return assets;
    }

    /// @dev - requestRedeem AND redeem over multiple deposit and principals into one requestRedeemPeriod
    function _testRedeemMultiDeposit(
        TestParamSet.TestUsers memory redeemUsers,
        IMultiTokenVault vault,
        TestParamSet.TestParam[] memory depositTestParams,
        uint256 redeemPeriod // we are testing multiple deposits into one redeemPeriod
    ) internal virtual override returns (uint256 assets_) {
        LiquidContinuousMultiTokenVault liquidVault = LiquidContinuousMultiTokenVault(address(vault));

        // first requestRedeem
        _testRequestRedeemMultiDeposit(redeemUsers, liquidVault, depositTestParams, redeemPeriod);

        // now redeem
        return _testRedeemAfterRequestRedeemMultiDeposit(redeemUsers, vault, depositTestParams, redeemPeriod);
    }

    /// @dev redeem across multiple deposit periods
    function _vaultRedeemBatch(
        TestParamSet.TestUsers memory redeemUsers,
        IMultiTokenVault vault,
        TestParamSet.TestParam[] memory depositTestParams,
        uint256 redeemPeriod
    ) internal virtual override returns (uint256 assets_) {
        LiquidContinuousMultiTokenVault liquidVault = LiquidContinuousMultiTokenVault(address(vault));

        _warpToPeriod(vault, redeemPeriod); // warp the vault to redeem period

        // authorize the tokenOperator
        vm.prank(redeemUsers.tokenOwner);
        vault.setApprovalForAll(redeemUsers.tokenOperator, true);

        vm.prank(redeemUsers.tokenOperator);
        uint256 assets =
            liquidVault.redeem(depositTestParams.totalPrincipal(), redeemUsers.tokenReceiver, redeemUsers.tokenOperator);

        // de-authorize the tokenOperator
        vm.prank(redeemUsers.tokenOwner);
        vault.setApprovalForAll(redeemUsers.tokenOperator, false);

        return assets;
    }

    function _expectedReturns(uint256, /* shares */ IVault vault, TestParamSet.TestParam memory testParam)
        internal
        view
        override
        returns (uint256 expectedReturns_)
    {
        LiquidContinuousMultiTokenVault liquidVault = LiquidContinuousMultiTokenVault(address(vault));

        // LiquidStone stops accruing yield at the requestRedeem period
        uint256 requestRedeemPeriod = testParam.redeemPeriod - _liquidVault.noticePeriod();

        return liquidVault._yieldStrategy().calcYield(
            address(vault), testParam.principal, testParam.depositPeriod, requestRedeemPeriod
        );
    }

    /// @dev this assumes timePeriod is in days
    function _warpToPeriod(IVault vault, uint256 timePeriod) internal override {
        LiquidContinuousMultiTokenVault liquidVault = LiquidContinuousMultiTokenVault(address(vault));

        uint256 warpToTimeInSeconds = liquidVault._vaultStartTimestamp() + timePeriod * 24 hours;

        vm.warp(warpToTimeInSeconds);
    }

    // simple scenario with only one user
    function _createTestUsers(address account)
        internal
        virtual
        override
        returns (TestParamSet.TestUsers memory depositUsers_, TestParamSet.TestUsers memory redeemUsers_)
    {
        (TestParamSet.TestUsers memory depositUsers, TestParamSet.TestUsers memory redeemUsers) =
            super._createTestUsers(account);

        // in LiquidContinuousMultiTokenVault - tokenOwner and tokenOperator (aka controller) must be the same
        // because IComponentToken.redeem() does not have an `owner` parameter.  // TODO - we should add this in with Plume !
        TestParamSet.TestUsers memory redeemUsersOperatorIsOwner = TestParamSet.TestUsers({
            tokenOwner: redeemUsers.tokenOwner,
            tokenReceiver: redeemUsers.tokenReceiver,
            tokenOperator: redeemUsers.tokenOwner
        });

        return (depositUsers, redeemUsersOperatorIsOwner);
    }

    function _setPeriod(address operator, LiquidContinuousMultiTokenVault vault, uint256 newPeriod) public {
        uint256 newPeriodInSeconds = newPeriod * 1 days;
        uint256 currentTime = Timer.timestamp();

        uint256 newStartTime =
            currentTime > newPeriodInSeconds ? (currentTime - newPeriodInSeconds) : (newPeriodInSeconds - currentTime);

        vm.prank(operator);
        vault.setVaultStartTimestamp(newStartTime);
    }

    function _asSingletonArray(uint256 element) internal pure returns (uint256[] memory array) {
        array = new uint256[](1);
        array[0] = element;
    }

    function getOwner() public view returns (address) {
        return _vaultAuth.owner;
    }

    function getOperator() public view returns (address) {
        return _vaultAuth.operator;
    }

    function getUpgrader() public view returns (address) {
        return _vaultAuth.upgrader;
    }

    function getAssetManager() public view returns (address) {
        return _vaultAuth.assetManager;
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
