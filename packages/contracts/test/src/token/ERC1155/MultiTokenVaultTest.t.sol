// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IMultiTokenVault } from "@credbull/token/ERC1155/IMultiTokenVault.sol";
import { MultiTokenVault } from "@credbull/token/ERC1155/MultiTokenVault.sol";
import { IMultiTokenVaultTestBase } from "./IMultiTokenVaultTestBase.t.sol";

import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract MultiTokenVaulTest is IMultiTokenVaultTestBase {
    IERC20Metadata private asset;

    IMultiTokenVaultTestParams private deposit1TestParams;
    IMultiTokenVaultTestParams private deposit2TestParams;

    uint256 internal SCALE;

    function setUp() public {
        vm.prank(owner);
        asset = new SimpleUSDC(1_000_000 ether);

        SCALE = 10 ** asset.decimals();
        _transferAndAssert(asset, owner, alice, 100_000 * SCALE);

        deposit1TestParams = IMultiTokenVaultTestParams({ principal: 500 * SCALE, depositPeriod: 10, redeemPeriod: 21 });
        deposit2TestParams = IMultiTokenVaultTestParams({ principal: 300 * SCALE, depositPeriod: 15, redeemPeriod: 17 });
    }

    function test__MultiTokenVaulTest__SimpleDeposit() public {
        uint256 assetToSharesRatio = 1;

        MultiTokenVault vault = new SimpleMultiTokenVault(asset, assetToSharesRatio, 10, owner);

        address vaultAddress = address(vault);

        assertEq(0, asset.allowance(alice, vaultAddress), "vault shouldn't have an allowance to start");
        assertEq(0, asset.balanceOf(vaultAddress), "vault shouldn't have a balance to start");

        vm.startPrank(alice);
        asset.approve(vaultAddress, deposit1TestParams.principal);

        assertEq(deposit1TestParams.principal, asset.allowance(alice, vaultAddress), "vault should have allowance");
        vm.stopPrank();

        vm.startPrank(alice);
        vault.deposit(deposit1TestParams.principal, alice);
        vm.stopPrank();

        assertEq(deposit1TestParams.principal, asset.balanceOf(vaultAddress), "vault should have the asset");
        assertEq(0, asset.allowance(alice, vaultAddress), "vault shouldn't have an allowance after deposit");

        testVaultAtPeriods(vault, deposit1TestParams);
    }

    // Scenario: Calculating returns for a standard investment
    function test__MultiTokenVaulTest__MultipleDeposits() public {
        uint256 assetToSharesRatio = 2;

        // setup
        MultiTokenVault vault = new SimpleMultiTokenVault(asset, assetToSharesRatio, 10, owner);
        uint256 assetBalanceBeforeDeposits = asset.balanceOf(alice); // the asset balance from the start

        // verify deposit - period 1
        uint256 deposit1Shares = _testDepositOnly(alice, vault, deposit1TestParams);
        assertEq(
            deposit1TestParams.principal / assetToSharesRatio, deposit1Shares, "deposit shares incorrect at period 1"
        );
        assertEq(
            deposit1Shares,
            vault.sharesAtPeriod(alice, deposit1TestParams.depositPeriod),
            "getSharesAtPeriod incorrect at period 1"
        );
        assertEq(
            deposit1Shares, vault.balanceOf(alice, deposit1TestParams.depositPeriod), "balance incorrect at period 1"
        );
        assertEq(
            deposit1Shares, vault.balanceOf(alice, deposit1TestParams.depositPeriod), "balance incorrect at period 1"
        );

        // verify deposit - period 2
        uint256 deposit2Shares = _testDepositOnly(alice, vault, deposit2TestParams);
        assertEq(
            deposit2TestParams.principal / assetToSharesRatio, deposit2Shares, "deposit shares incorrect at period 2"
        );
        assertEq(
            deposit2Shares,
            vault.sharesAtPeriod(alice, deposit2TestParams.depositPeriod),
            "getSharesAtPeriod incorrect at period 2"
        );
        assertEq(
            deposit2Shares, vault.balanceOf(alice, deposit2TestParams.depositPeriod), "balance incorrect at period 2"
        );

        // verify redeem - period 1
        uint256 deposit1ExpectedYield = _expectedReturns(deposit1Shares, vault, deposit1TestParams);
        uint256 deposit1Assets = _testRedeemOnly(
            alice, vault, deposit1TestParams, deposit1Shares, assetBalanceBeforeDeposits - deposit2TestParams.principal
        );
        assertApproxEqAbs(
            deposit1TestParams.principal + deposit1ExpectedYield,
            deposit1Assets,
            TOLERANCE,
            "deposit1 deposit assets incorrect"
        );

        // verify redeem - period 2
        uint256 deposit2Assets = _testRedeemOnly(
            alice, vault, deposit2TestParams, deposit2Shares, assetBalanceBeforeDeposits + deposit1ExpectedYield
        );
        assertApproxEqAbs(
            deposit2TestParams.principal + _expectedReturns(deposit1Shares, vault, deposit2TestParams),
            deposit2Assets,
            TOLERANCE,
            "deposit2 deposit assets incorrect"
        );

        testVaultAtPeriods(vault, deposit1TestParams);
        testVaultAtPeriods(vault, deposit2TestParams);
    }

    function _expectedReturns(
        uint256, /* shares */
        IMultiTokenVault vault,
        IMultiTokenVaultTestParams memory testParams
    ) internal view override returns (uint256 expectedReturns_) {
        SimpleMultiTokenVault simpleMultitokenVault = SimpleMultiTokenVault(address(vault));

        return simpleMultitokenVault.calcYield(testParams.principal, testParams.depositPeriod, testParams.redeemPeriod);
    }
}

contract SimpleMultiTokenVault is MultiTokenVault {
    uint256 internal immutable ASSET_TO_SHARES_RATIO;
    uint256 internal immutable YIELD_PERCENTAGE;

    constructor(IERC20Metadata asset, uint256 assetToSharesRatio, uint256 yieldPercentage, address initialOwner)
        MultiTokenVault(asset, initialOwner)
    {
        ASSET_TO_SHARES_RATIO = assetToSharesRatio;
        YIELD_PERCENTAGE = yieldPercentage;
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
