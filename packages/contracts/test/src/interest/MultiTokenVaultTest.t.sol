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

    IMultiTokenVaultTestParams private deposit1TestParams;
    IMultiTokenVaultTestParams private deposit2TestParams;

    uint256 internal SCALE;

    function setUp() public {
        vm.prank(owner);
        asset = new SimpleUSDC(1_000_000 ether);

        SCALE = 10 ** asset.decimals();
        _transferAndAssert(asset, owner, alice, 100_000 * SCALE);

        depositLedger = new SimpleIERC1155Mintable();

        deposit1TestParams = IMultiTokenVaultTestParams({ principal: 500 * SCALE, depositPeriod: 10, redeemPeriod: 21 });

        deposit2TestParams = IMultiTokenVaultTestParams({ principal: 300 * SCALE, depositPeriod: 15, redeemPeriod: 17 });
    }

    // Scenario: Calculating returns for a standard investment
    function test__MultiTokenVaulTest__MultipleDeposits() public {
        uint256 assetToSharesRatio = 2;

        // setup
        MultiTokenVault vault = new SimpleMultiTokenVault(asset, depositLedger, assetToSharesRatio, 10);
        uint256 assetBalanceBeforeDeposits = asset.balanceOf(alice); // the asset balance from the start

        // verify deposit - period 1
        uint256 deposit1Shares = _testDepositOnly(alice, vault, deposit1TestParams);
        assertEq(
            deposit1TestParams.principal / assetToSharesRatio, deposit1Shares, "deposit shares incorrect at period 1"
        );
        assertEq(
            deposit1Shares,
            vault.getSharesAtPeriod(alice, deposit1TestParams.depositPeriod),
            "getSharesAtPeriod incorrect at period 1"
        );
        assertEq(deposit1Shares, vault.balanceOf(alice), "balance incorrect at period 1");

        // verify deposit - period 2
        uint256 deposit2Shares = _testDepositOnly(alice, vault, deposit2TestParams);
        assertEq(
            deposit2TestParams.principal / assetToSharesRatio, deposit2Shares, "deposit shares incorrect at period 2"
        );
        assertEq(
            deposit2Shares,
            vault.getSharesAtPeriod(alice, deposit2TestParams.depositPeriod),
            "getSharesAtPeriod incorrect at period 2"
        );
        assertEq(deposit1Shares + deposit2Shares, vault.balanceOf(alice), "balance incorrect at period 2");

        // verify redeem - period 1
        uint256 deposit1ExpectedYield = vault.calcYield(deposit1TestParams.principal, 0, 0);
        uint256 deposit1Assets = _testRedeemOnly(
            alice, vault, deposit1TestParams, deposit1Shares, assetBalanceBeforeDeposits - deposit2TestParams.principal
        );
        assertApproxEqAbs(
            deposit1TestParams.principal + vault.calcYield(deposit1TestParams.principal, 0, 0),
            deposit1Assets,
            TOLERANCE,
            "deposit1 deposit assets incorrect"
        );

        // verify redeem - period 2
        uint256 deposit2Assets = _testRedeemOnly(
            alice, vault, deposit2TestParams, deposit2Shares, assetBalanceBeforeDeposits + deposit1ExpectedYield
        );
        assertApproxEqAbs(
            deposit2TestParams.principal + vault.calcYield(deposit2TestParams.principal, 0, 0),
            deposit2Assets,
            TOLERANCE,
            "deposit2 deposit assets incorrect"
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
