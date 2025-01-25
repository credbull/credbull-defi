// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { LiquidContinuousMultiTokenVault } from "@credbull/yield/LiquidContinuousMultiTokenVault.sol";
import { TripleRateYieldStrategy } from "@credbull/yield/strategy/TripleRateYieldStrategy.sol";
import { IRedeemOptimizer } from "@credbull/token/ERC1155/IRedeemOptimizer.sol";
import { RedeemOptimizerFIFO } from "@credbull/token/ERC1155/RedeemOptimizerFIFO.sol";

import { DeployLiquidMultiTokenVault } from "@script/DeployLiquidMultiTokenVault.s.sol";
import { LiquidContinuousMultiTokenVaultVerifier } from "@test/test/yield/LiquidContinuousMultiTokenVaultVerifier.t.sol";
import { TestParamSet } from "@test/test/token/ERC1155/TestParamSet.t.sol";

import { IVaultTestSuite } from "@test/src/token/ERC4626/IVaultTestSuite.t.sol";

abstract contract LiquidContinuousMultiTokenVaultTestBase is IVaultTestSuite {
    using TestParamSet for TestParamSet.TestParam[];

    LiquidContinuousMultiTokenVault internal _liquidVault;
    LiquidContinuousMultiTokenVaultVerifier internal _liquidVerifier;

    LiquidContinuousMultiTokenVault.VaultAuth internal _vaultAuth = LiquidContinuousMultiTokenVault.VaultAuth({
        owner: makeAddr("owner"),
        operator: makeAddr("operator"),
        upgrader: makeAddr("upgrader"),
        assetManager: makeAddr("assetManager")
    });

    function setUp() public override {
        DeployLiquidMultiTokenVault _deployVault = new DeployLiquidMultiTokenVault();
        _liquidVault = _deployVault.run(_vaultAuth);
        _liquidVerifier = new LiquidContinuousMultiTokenVaultVerifier();
        _tenor = _liquidVault.TENOR();

        // warp to a "real time" time rather than block.timestamp=1
        vm.warp(_liquidVault._vaultStartTimestamp() + 1);

        init(_liquidVault, _liquidVerifier);
    }

    // LiquidStone exception case - [FAIL: RedeemOptimizer__OptimizerFailed(0, 106000000 [1.06e8])]
    function test__IVaultSuite__DepositPreTenorRedeemPreTenor() public override {
        (TestParamSet.TestUsers memory depositUsers, TestParamSet.TestUsers memory redeemUsers) =
            _liquidVerifier._createTestUsers(_alice);

        TestParamSet.TestParam[] memory testParams = new TestParamSet.TestParam[](1);
        testParams[0] =
            TestParamSet.TestParam({ principal: 106 * _scale, depositPeriod: _tenor - 1, redeemPeriod: _tenor - 1 });

        uint256[] memory sharesAtPeriods =
            _liquidVerifier._verifyDepositOnlyBatch(depositUsers, _liquidVault, testParams);

        vm.expectRevert(
            abi.encodeWithSelector(
                RedeemOptimizerFIFO.RedeemOptimizer__OptimizerFailed.selector, 0, testParams[0].principal
            )
        );
        _liquidVerifier._verifyRedeemOnlyBatch(redeemUsers, _liquidVault, testParams, sharesAtPeriods);
    }

    function _createVaultParams(LiquidContinuousMultiTokenVault.VaultAuth memory vaultAuth)
        internal
        returns (LiquidContinuousMultiTokenVault.VaultParams memory vaultParams_)
    {
        DeployLiquidMultiTokenVault deployVault = new DeployLiquidMultiTokenVault();

        IRedeemOptimizer redeemOptimizer = new RedeemOptimizerFIFO(IRedeemOptimizer.OptimizerBasis.Shares, 0);

        LiquidContinuousMultiTokenVault.VaultParams memory vaultParams = deployVault._createVaultParams(
            vaultAuth, _createAsset(vaultAuth.owner), new TripleRateYieldStrategy(), redeemOptimizer
        );

        return vaultParams;
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
