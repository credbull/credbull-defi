// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IVault } from "@credbull/token/ERC4626/IVault.sol";
import { LiquidContinuousMultiTokenVault } from "@credbull/yield/LiquidContinuousMultiTokenVault.sol";
import { IYieldStrategy } from "@credbull/yield/strategy/IYieldStrategy.sol";
import { TripleRateYieldStrategy } from "@credbull/yield/strategy/TripleRateYieldStrategy.sol";
import { IRedeemOptimizer } from "@credbull/token/ERC1155/IRedeemOptimizer.sol";
import { RedeemOptimizerFIFO } from "@credbull/token/ERC1155/RedeemOptimizerFIFO.sol";

import { DeployLiquidMultiTokenVault } from "@script/DeployLiquidMultiTokenVault.s.sol";
import { LiquidContinuousMultiTokenVaultVerifier } from "@test/test/yield/LiquidContinuousMultiTokenVaultVerifier.t.sol";
import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";
import { TestParamSet } from "@test/test/token/ERC1155/TestParamSet.t.sol";

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { IVaultTestSuite } from "@test/src/token/ERC4626/IVaultTestSuite.t.sol";
import { IVaultVerifier } from "@test/test/token/ERC4626/IVaultVerifier.t.sol";

// TODO - Should this extend MultiTokenVaultTest instead?
abstract contract LiquidContinuousMultiTokenVaultTestBase is IVaultTestSuite {
    using TestParamSet for TestParamSet.TestParam[];

    LiquidContinuousMultiTokenVault internal _liquidVault;
    LiquidContinuousMultiTokenVaultVerifier internal _verifier;

    LiquidContinuousMultiTokenVault.VaultAuth internal _vaultAuth = LiquidContinuousMultiTokenVault.VaultAuth({
        owner: makeAddr("owner"),
        operator: makeAddr("operator"),
        upgrader: makeAddr("upgrader"),
        assetManager: makeAddr("assetManager")
    });

    function setUp() public virtual override {
        DeployLiquidMultiTokenVault _deployVault = new DeployLiquidMultiTokenVault();
        _liquidVault = _deployVault.run(_vaultAuth);
        _verifier = new LiquidContinuousMultiTokenVaultVerifier();

        // warp to a "real time" time rather than block.timestamp=1
        vm.warp(_liquidVault._vaultStartTimestamp() + 1);

        setUpAsset(IERC20Metadata(_liquidVault.asset()));
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

    function _vault() internal virtual override returns (IVault) {
        return _liquidVault;
    }

    function _vaultVerifier() internal virtual override returns (IVaultVerifier verifier) {
        return _verifier;
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
