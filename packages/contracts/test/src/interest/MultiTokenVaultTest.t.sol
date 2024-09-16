// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { MultiTokenVault } from "@credbull/interest/MultiTokenVault.sol";
import { IMultiTokenVaultTestBase } from "@test/src/interest/IMultiTokenVaultTestBase.t.sol";
import { IERC1155MintAndBurnable } from "@credbull/interest/IERC1155MintAndBurnable.sol";
import { SimpleIERC1155Mintable } from "@test/src/interest/SimpleIERC1155Mintable.t.sol";

import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

contract MultiTokenVaulTest is IMultiTokenVaultTestBase {
    using Math for uint256;

    IERC20Metadata private asset;
    IERC1155MintAndBurnable private depositLedger;

    uint256 internal SCALE;

    function setUp() public {
        vm.prank(owner);
        asset = new SimpleUSDC(1_000_000 ether);

        SCALE = 10 ** asset.decimals();
        _transferAndAssert(asset, owner, alice, 100_000 * SCALE);

        depositLedger = new SimpleIERC1155Mintable();
    }

    // Scenario: Calculating returns for a standard investment
    function test__MultiTokenVaulTest__MultipleDeposits() public {
        uint256 assetToSharesRatio = 2;

        MultiTokenVault vault = new SimpleMultiTokenVault(asset, depositLedger, assetToSharesRatio, 10);
        uint256 startingAssetBalance = asset.balanceOf(alice);

        uint256 deposit1Period = 10;
        uint256 deposit1Amount = 500 * SCALE;

        // verify deposit - period 1
        uint256 deposit1Shares = _testDepositOnly(alice, deposit1Amount, vault, deposit1Period);
        assertEq(deposit1Amount / assetToSharesRatio, deposit1Shares, "deposit1 deposit shares incorrect");
        assertEq(
            deposit1Shares, vault.getSharesAtPeriod(alice, deposit1Period), "getSharesAtPeriod incorrect at period 1"
        );

        // verify redeem - period 1
        uint256 deposit1Assets = _testRedeemOnly(
            owner,
            alice,
            deposit1Amount,
            vault,
            deposit1Period,
            deposit1Period + 100,
            deposit1Shares,
            startingAssetBalance
        );
        assertApproxEqAbs(
            deposit1Amount + vault.calcYield(deposit1Amount, 0, 0),
            deposit1Assets,
            TOLERANCE,
            "deposit1 deposit assets incorrect"
        );

        // verify deposit - period 2
        uint256 deposit2Period = 15;
        uint256 deposit2Amount = 300 * SCALE;
        uint256 deposit2Shares = _testDepositOnly(alice, deposit2Amount, vault, deposit2Period);
        assertEq(deposit2Amount / assetToSharesRatio, deposit2Shares, "deposit2 deposit shares incorrect");
        assertEq(
            deposit2Shares, vault.getSharesAtPeriod(alice, deposit2Period), "getSharesAtPeriod incorrect at period 2"
        );
    }
}

contract SimpleMultiTokenVault is MultiTokenVault {
    uint256 internal immutable ASSET_TO_SHARES_RATIO;
    uint256 internal immutable YIELD_PERCENTAGE;

    constructor(IERC20Metadata asset, IERC1155MintAndBurnable depositLedger, uint256 assetToSharesRatio, uint256 yield)
        MultiTokenVault(asset, depositLedger)
    {
        ASSET_TO_SHARES_RATIO = assetToSharesRatio;
        YIELD_PERCENTAGE = yield;
    }

    function calcYield(uint256 principal, uint256, /* depositPeriod */ uint256 /* toPeriod */ )
        public
        view
        returns (uint256 yield)
    {
        return principal * YIELD_PERCENTAGE / 100;
    }

    function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod, uint256 redeemPeriod)
        public
        view
        override
        returns (uint256 assets)
    {
        uint256 principal = shares * ASSET_TO_SHARES_RATIO;

        return principal + calcYield(principal, depositPeriod, redeemPeriod);
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
