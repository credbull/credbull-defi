// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IRedeemOptimizer } from "@credbull/token/ERC1155/IRedeemOptimizer.sol";
import { RedeemOptimizerFIFO } from "@credbull/token/ERC1155/RedeemOptimizerFIFO.sol";
import { IMultiTokenVault } from "@credbull/token/ERC1155/IMultiTokenVault.sol";

import { MultiTokenVaultTest } from "@test/src/token/ERC1155/MultiTokenVaultTest.t.sol";

contract RedeemOptimizerTest is MultiTokenVaultTest {
    address private owner = makeAddr("owner");
    address private alice = makeAddr("alice");

    function setUp() public override {
        super.setUp();
    }

    // Scenario: Calculating returns for a standard investment
    function test__RedeemOptimizerTest__MultipleDeposits() public {
        uint256 assetToSharesRatio = 2;

        // setup
        IMultiTokenVault multiTokenVault = _createMultiTokenVault(asset, assetToSharesRatio, 10);
        IRedeemOptimizer redeemOptimizer = new RedeemOptimizerFIFO(multiTokenVault.currentPeriodsElapsed());

        (uint256[] memory depositPeriods, uint256[] memory depositShares) = _testDeposits(alice, multiTokenVault); // make a few deposits
        uint256 totalDepositShares = depositShares[0] + depositShares[1] + depositShares[2];

        // warp vault ahead redeemPeriod
        uint256 redeemPeriod = deposit3TestParams.redeemPeriod;
        _warpToPeriod(multiTokenVault, redeemPeriod);

        // check full redeem
        (uint256[] memory redeemDepositPeriods, uint256[] memory sharesAtPeriods) =
            redeemOptimizer.optimizeRedeemShares(multiTokenVault, alice, totalDepositShares, redeemPeriod);

        assertEq(3, redeemDepositPeriods.length, "depositPeriods wrong length - full redeem");
        assertEq(3, sharesAtPeriods.length, "sharesAtPeriods wrong length - full redeem");

        assertEq(deposit1TestParams.depositPeriod, redeemDepositPeriods[0], "optimizeRedeem - wrong depositPeriod 0");
        assertEq(depositShares[0], sharesAtPeriods[0], "optimizeRedeem - wrong shares 0");

        assertEq(deposit2TestParams.depositPeriod, redeemDepositPeriods[1], "optimizeRedeem - wrong depositPeriod 1");
        assertEq(depositShares[1], sharesAtPeriods[1], "optimizeRedeem - wrong shares 1");

        assertEq(deposit3TestParams.depositPeriod, redeemDepositPeriods[2], "optimizeRedeem - wrong depositPeriod 2");
        assertEq(depositShares[2], sharesAtPeriods[2], "optimizeRedeem - wrong shares 2");

        // Check full withdraw
        uint256[] memory expectedAssetsAtPeriods =
            multiTokenVault.convertToAssetsForDepositPeriods(depositShares, depositPeriods, redeemPeriod);

        (uint256[] memory withdrawDepositPeriods, uint256[] memory actualAssetsAtPeriods) =
            redeemOptimizer.optimizeWithdrawAssets(multiTokenVault, alice, totalDepositShares, redeemPeriod);

        assertEq(2, withdrawDepositPeriods.length, "depositPeriods wrong length - full redeem");
        assertEq(2, actualAssetsAtPeriods.length, "sharesAtPeriods wrong length - full redeem");

        assertEq(deposit1TestParams.depositPeriod, withdrawDepositPeriods[0], "optimizeWithdraw - wrong depositPeriod");
        assertEq(expectedAssetsAtPeriods[0], actualAssetsAtPeriods[0], "optimizeWithdraw - wrong assets");

        // This is a partial amount, as the 2 amounts satisfy the 'to find' criterion.
        assertEq(deposit2TestParams.depositPeriod, withdrawDepositPeriods[1], "optimizeWithdraw - wrong depositPeriod");
        assertEq(200 * SCALE, actualAssetsAtPeriods[1], "optimizeWithdraw - wrong partial assets");
    }

    function test__RedeemOptimizerTest__InsufficientSharesShouldRevert() public {
        IMultiTokenVault multiTokenVault = _createMultiTokenVault(asset, 1, 10);
        uint256 vaultCurrentPeriod = multiTokenVault.currentPeriodsElapsed();

        // no deposits - should fail
        uint256 oneShare = 1;
        IRedeemOptimizer redeemOptimizer = new RedeemOptimizerFIFO(vaultCurrentPeriod);
        vm.expectRevert(
            abi.encodeWithSelector(RedeemOptimizerFIFO.RedeemOptimizer__OptimizerFailed.selector, 0, oneShare)
        );
        redeemOptimizer.optimizeRedeemShares(multiTokenVault, alice, oneShare, vaultCurrentPeriod);

        // shares to find greater than the deposits
        uint256 deposit1Shares = _testDepositOnly(alice, multiTokenVault, deposit1TestParams);
        uint256 deposit2Shares = _testDepositOnly(alice, multiTokenVault, deposit2TestParams);
        uint256 totalDepositShares = deposit1Shares + deposit2Shares;

        uint256 sharesGreaterThanDeposits = totalDepositShares + 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                RedeemOptimizerFIFO.RedeemOptimizer__OptimizerFailed.selector, 0, sharesGreaterThanDeposits
            )
        );
        redeemOptimizer.optimizeRedeemShares(multiTokenVault, alice, sharesGreaterThanDeposits, vaultCurrentPeriod);
    }

    function test__RedeemOptimizerTest__InvalidPeriodRangeShouldRevert() public {
        IMultiTokenVault multiTokenVault = _createMultiTokenVault(asset, 1, 10);

        uint256 vaultCurrentPeriod = multiTokenVault.currentPeriodsElapsed();
        uint256 invalidFromDepositPeriod = vaultCurrentPeriod + 1; // from greater than to period is not allowed

        IRedeemOptimizer redeemOptimizer = new RedeemOptimizerFIFO(invalidFromDepositPeriod);
        vm.expectRevert(
            abi.encodeWithSelector(
                RedeemOptimizerFIFO.RedeemOptimizer__InvalidDepositPeriodRange.selector,
                invalidFromDepositPeriod,
                vaultCurrentPeriod
            )
        );
        redeemOptimizer.optimizeRedeemShares(multiTokenVault, alice, 1, vaultCurrentPeriod);
    }

    function test__RedeemOptimizerTest__FutureToPeriodShouldRevert() public {
        IMultiTokenVault multiTokenVault = _createMultiTokenVault(asset, 1, 10);

        uint256 vaultCurrentPeriod = multiTokenVault.currentPeriodsElapsed();
        uint256 invalidToDepositPeriod = vaultCurrentPeriod + 1; // future to period is not allowed

        RedeemOptimizerFIFOMock redeemOptimizerMock = new RedeemOptimizerFIFOMock(vaultCurrentPeriod);

        vm.expectRevert(
            abi.encodeWithSelector(
                RedeemOptimizerFIFO.RedeemOptimizer__FutureToDepositPeriod.selector,
                invalidToDepositPeriod,
                vaultCurrentPeriod
            )
        );
        redeemOptimizerMock.findAmount(
            multiTokenVault,
            alice,
            1,
            vaultCurrentPeriod,
            invalidToDepositPeriod,
            vaultCurrentPeriod,
            RedeemOptimizerFIFO.AmountType.Shares
        );
    }

    function _testDeposits(address receiver, IMultiTokenVault vault)
        internal
        returns (uint256[] memory depositPeriods_, uint256[] memory shares_)
    {
        uint256[] memory depositPeriods = new uint256[](3);
        uint256[] memory shares = new uint256[](3);

        depositPeriods[0] = deposit1TestParams.depositPeriod;
        depositPeriods[1] = deposit2TestParams.depositPeriod;
        depositPeriods[2] = deposit3TestParams.depositPeriod;

        shares[0] = _testDepositOnly(receiver, vault, deposit1TestParams);
        shares[1] = _testDepositOnly(receiver, vault, deposit2TestParams);
        shares[2] = _testDepositOnly(receiver, vault, deposit3TestParams);

        return (depositPeriods, shares);
    }
}

contract RedeemOptimizerFIFOMock is RedeemOptimizerFIFO {
    constructor(uint256 startDepositPeriod) RedeemOptimizerFIFO(startDepositPeriod) { }

    // exposed to test failure scenarios

    function findAmount(
        IMultiTokenVault vault,
        address owner,
        uint256 amountToFind,
        uint256 fromDepositPeriod,
        uint256 toDepositPeriod,
        uint256 redeemPeriod,
        AmountType amountType
    ) public view returns (uint256[] memory depositPeriods, uint256[] memory amountAtPeriods) {
        return _findAmount(vault, owner, amountToFind, fromDepositPeriod, toDepositPeriod, redeemPeriod, amountType);
    }
}
