// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IComponentToken } from "@plume/contracts/nest/interfaces/IComponentToken.sol";
import { IERC7575 } from "@plume/contracts/nest/interfaces/IERC7575.sol";
import { AggregateToken } from "@plume/contracts/nest/AggregateToken.sol";
import { LiquidContinuousMultiTokenVaultTestBase } from "@test/test/yield/LiquidContinuousMultiTokenVaultTestBase.t.sol";
import { TestParamSet } from "@test/test/token/ERC1155/TestParamSet.t.sol";

import { IERC1155Receiver } from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import { DeployAggregateToken } from "@script/DeployAggregateToken.s.sol";

contract AggregateTokenTest is LiquidContinuousMultiTokenVaultTestBase {
    AggregateToken internal aggregateToken;
    address public aggTokenOwner;

    function setUp() public override {
        super.setUp();

        DeployAggregateToken deployAggToken = new DeployAggregateToken();
        aggTokenOwner = _vaultAuth.owner;
        aggregateToken = deployAggToken.run(aggTokenOwner, address(_asset));
    }

    function test__AggregateTokenTest__SupportsInterface() public view {
        assertTrue(aggregateToken.supportsInterface(type(IERC1155Receiver).interfaceId));
        assertTrue(aggregateToken.supportsInterface(type(IERC7575).interfaceId));
        assertTrue(aggregateToken.supportsInterface(0xe3bc4e65));
    }

    function test__AggregateTokenTest__BuyComponentToken() public {
        uint256 depositAmount = 2_000 * _scale;

        _depositAssetsAggregateToken(alice, depositAmount);

        assertEq(
            depositAmount,
            _asset.balanceOf(address(aggregateToken)),
            "The asset balance of AggregateToken should be equal to the depositAmount, as it is the first deposit"
        );

        // Call buyComponentToken
        vm.startPrank(aggTokenOwner);
        aggregateToken.approveComponentToken(IComponentToken(address(_liquidVault)), depositAmount);
        aggregateToken.buyComponentToken(IComponentToken(address(_liquidVault)), depositAmount);
        vm.stopPrank();

        assertEq(
            depositAmount,
            _liquidVault.balanceOf(address(aggregateToken), _liquidVault.currentPeriod()),
            "AggregateToken should receive ERC1155 token shares equal to the depositAmount"
        );
        assertEq(0, _asset.balanceOf(address(aggregateToken)), "There shouldn't be any remaining amount");
    }

    function test__AggregateTokenTest__SellComponentToken() public {
        TestParamSet.TestParam memory testParams =
            TestParamSet.TestParam({ principal: 2_000 * _scale, depositPeriod: 10, redeemPeriod: 70 });

        // Move the blocktime to depositPeriod
        _warpToPeriod(_liquidVault, testParams.depositPeriod);

        _depositAssetsAggregateToken(alice, testParams.principal);

        assertEq(
            testParams.principal,
            _asset.balanceOf(address(aggregateToken)),
            "The asset balance of AggregateToken should be equal to the principal, as it is the first deposit"
        );

        // Call buyComponentToken
        vm.startPrank(aggTokenOwner);
        aggregateToken.approveComponentToken(IComponentToken(address(_liquidVault)), testParams.principal);
        aggregateToken.buyComponentToken(IComponentToken(address(_liquidVault)), testParams.principal);
        vm.stopPrank();

        assertEq(0, _asset.balanceOf(address(aggregateToken)), "There shouldn't be any remaining amount");
        assertEq(
            testParams.principal,
            _liquidVault.balanceOf(address(aggregateToken), testParams.depositPeriod),
            "AggregateToken should receive ERC1155 token shares equal to the principal"
        );

        // Invest assets to the liquidStone
        uint256 investAmount = 2_000 * _scale;
        _investToLiquidStone(investAmount);

        // Move the blocktime to request redeem
        _warpToPeriod(_liquidVault, testParams.redeemPeriod - _liquidVault.noticePeriod());

        // Call requestSellComponentToken (newly added by us)
        vm.prank(aggTokenOwner);
        aggregateToken.requestSellComponentToken(IComponentToken(address(_liquidVault)), testParams.principal);

        // Move the blocktime to redeemPeriod
        _warpToPeriod(_liquidVault, testParams.redeemPeriod);

        // Call sellComponentToken
        vm.prank(aggTokenOwner);
        aggregateToken.sellComponentToken(IComponentToken(address(_liquidVault)), testParams.principal);

        uint256 expectedAmount = testParams.principal + _expectedReturns(0, _liquidVault, testParams);
        assertEq(expectedAmount, _asset.balanceOf(address(aggregateToken)));
        assertEq(0, _liquidVault.balanceOf(address(aggregateToken), testParams.depositPeriod));
        assertEq(investAmount + testParams.principal - expectedAmount, _asset.balanceOf(address(_liquidVault)));
    }

    /// @dev Deposits assets into AggregateToken
    function _depositAssetsAggregateToken(address user, uint256 depositAmount) internal {
        vm.startPrank(user);
        _asset.approve(address(aggregateToken), depositAmount);
        aggregateToken.deposit(depositAmount, user, user);
        vm.stopPrank();
    }

    function _investToLiquidStone(uint256 investAmount) internal {
        vm.prank(bob);
        _asset.transfer(address(_liquidVault), investAmount);
    }
}
