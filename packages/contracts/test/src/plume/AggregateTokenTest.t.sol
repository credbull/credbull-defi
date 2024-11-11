// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IComponentToken } from "@plume/contracts/nest/interfaces/IComponentToken.sol";
import { AggregateToken } from "@plume/contracts/nest/AggregateToken.sol";
import { LiquidContinuousMultiTokenVaultTestBase } from "@test/test/yield/LiquidContinuousMultiTokenVaultTestBase.t.sol";
import { AggregateTokenProxy } from "@plume/contracts/nest/proxy/AggregateTokenProxy.sol";
import { TestParamSet } from "@test/test/token/ERC1155/TestParamSet.t.sol";
import { console2 } from "forge-std/console2.sol";

contract AggregateTokenTest is LiquidContinuousMultiTokenVaultTestBase {
    AggregateToken internal aggregateToken;
    address public NEST_ADMIN_ADDRESS = makeAddr("NEST_ADMIN_ADDRESS");

    function setUp() public override {
        super.setUp();

        // Deploy implementation of AggregateToken
        AggregateToken aggregateTokenImpl = new AggregateToken();

        // Deploy proxy of AggregateToken
        AggregateTokenProxy aggregateTokenProxy = new AggregateTokenProxy(
            address(aggregateTokenImpl),
            abi.encodeCall(
                AggregateToken.initialize,
                (NEST_ADMIN_ADDRESS, "Aggregate Token", "AGGT", IComponentToken(address(_asset)), 15e17, 12e17)
            )
        );

        aggregateToken = AggregateToken(address(aggregateTokenProxy));
    }

    function test__AggregateTokenTest__BuyComponentToken() public {
        uint256 depositAmount = 2_000 * _scale;

        _depositAssets_AggregateToken(alice, depositAmount);

        assertEq(
            depositAmount,
            _asset.balanceOf(address(aggregateToken)),
            "The asset balance of AggregateToken should be equal to the depositAmount, as it is the first deposit"
        );

        // Call buyComponentToken
        vm.prank(NEST_ADMIN_ADDRESS);
        aggregateToken.buyComponentToken(IComponentToken(address(_liquidVault)), depositAmount);

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

        _depositAssets_AggregateToken(alice, testParams.principal);

        assertEq(
            testParams.principal,
            _asset.balanceOf(address(aggregateToken)),
            "The asset balance of AggregateToken should be equal to the principal, as it is the first deposit"
        );

        // Call buyComponentToken
        vm.prank(NEST_ADMIN_ADDRESS);
        aggregateToken.buyComponentToken(IComponentToken(address(_liquidVault)), testParams.principal);

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
        vm.prank(NEST_ADMIN_ADDRESS);
        aggregateToken.requestSellComponentToken(IComponentToken(address(_liquidVault)), testParams.principal);

        // Move the blocktime to redeemPeriod
        _warpToPeriod(_liquidVault, testParams.redeemPeriod);

        // Call sellComponentToken
        vm.prank(NEST_ADMIN_ADDRESS);
        aggregateToken.sellComponentToken(IComponentToken(address(_liquidVault)), testParams.principal);

        uint256 expectedAmount = testParams.principal + _expectedReturns(0, _liquidVault, testParams);
        assertEq(expectedAmount, _asset.balanceOf(address(aggregateToken)));
        assertEq(0, _liquidVault.balanceOf(address(aggregateToken), testParams.depositPeriod));
        assertEq(investAmount + testParams.principal - expectedAmount, _asset.balanceOf(address(_liquidVault)));
    }

    /// @dev Deposits assets into AggregateToken
    function _depositAssets_AggregateToken(address user, uint256 depositAmount) internal {
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
