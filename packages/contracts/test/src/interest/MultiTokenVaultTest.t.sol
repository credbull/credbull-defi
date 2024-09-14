// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { MultiTokenVault } from "@credbull/interest/MultiTokenVault.sol";
import { MultiTokenVaultTestBase } from "@test/src/interest/MultiTokenVaultTestBase.t.sol";

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract SimpleMultiTokenVault is MultiTokenVault {
    uint256 internal immutable ASSET_TO_SHARES_RATIO;
    uint256 internal immutable YIELD_PERCENTAGE;

    constructor(IERC20Metadata asset, uint256 assetToSharesRatio, uint256 yieldPercentage) MultiTokenVault(asset) {
        ASSET_TO_SHARES_RATIO = assetToSharesRatio;
        YIELD_PERCENTAGE = yieldPercentage;
    }

    function calcYield(uint256 principal, uint256, /* depositPeriod */ uint256 /* toPeriod */ )
        external
        view
        returns (uint256 yield)
    {
        return principal * YIELD_PERCENTAGE / 100;
    }

    function convertToAssetsForDepositPeriod(uint256 shares, uint256, /* depositPeriod */ uint256 /* redeemPeriod */ )
        public
        view
        override
        returns (uint256 assets)
    {
        return shares * ASSET_TO_SHARES_RATIO;
    }

    function convertToSharesForDepositPeriod(uint256 assets, uint256 /* depositPeriod */ )
        public
        view
        override
        returns (uint256 shares)
    {
        return assets / ASSET_TO_SHARES_RATIO;
    }
}

contract MultiTokenVaulTest is MultiTokenVaultTestBase {
    using Math for uint256;

    IERC20Metadata private asset;
    uint256 internal SCALE;

    function setUp() public {
        vm.prank(owner);
        asset = new SimpleUSDC(1_000_000 ether);

        SCALE = 10 ** asset.decimals();
        transferAndAssert(asset, owner, alice, 100_000 * SCALE);
    }

    // Scenario: Calculating returns for a standard investment
    function test__MultiTokenVaulTest__MultipleDeposits() public {
        uint256 assetToSharesRatio = 2;
        uint256 yieldPercentage = 10;

        MultiTokenVault vault = new SimpleMultiTokenVault(asset, assetToSharesRatio, yieldPercentage);

        uint256 deposit1Period = 10;
        uint256 deposit1Amount = 500 * SCALE;
        uint256 deposit1Shares = testDepositOnly(alice, deposit1Amount, vault, deposit1Period);
        assertEq(deposit1Amount / assetToSharesRatio, deposit1Shares, "deposit1 shares incorrect");

        uint256 deposit2Period = 15;
        uint256 deposit2Amount = 300 * SCALE;
        uint256 deposit2Shares = testDepositOnly(alice, deposit2Amount, vault, deposit2Period);
        assertEq(deposit2Amount / assetToSharesRatio, deposit2Shares, "deposit2 shares incorrect");
    }
}
