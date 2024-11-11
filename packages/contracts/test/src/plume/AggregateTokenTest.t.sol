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

        AggregateToken aggregateTokenImpl = new AggregateToken();

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

        vm.startPrank(alice);
        _asset.approve(address(aggregateToken), depositAmount);
        aggregateToken.deposit(depositAmount, alice, alice);
        vm.stopPrank();

        assertEq(depositAmount, _asset.balanceOf(address(aggregateToken)));

        vm.prank(NEST_ADMIN_ADDRESS);
        aggregateToken.buyComponentToken(IComponentToken(address(_liquidVault)), depositAmount);

        assertEq(depositAmount, _liquidVault.balanceOf(address(aggregateToken), 0));
    }

    function test__AggregateTokenTest__SellComponentToken() public {
        TestParamSet.TestParam memory testParams =
            TestParamSet.TestParam({ principal: 2_000 * _scale, depositPeriod: 10, redeemPeriod: 70 });

        _warpToPeriod(_liquidVault, testParams.depositPeriod);

        vm.startPrank(alice);
        _asset.approve(address(aggregateToken), testParams.principal);
        aggregateToken.deposit(testParams.principal, alice, alice);
        vm.stopPrank();

        assertEq(testParams.principal, _asset.balanceOf(address(aggregateToken)));

        vm.prank(NEST_ADMIN_ADDRESS);
        aggregateToken.buyComponentToken(IComponentToken(address(_liquidVault)), testParams.principal);

        assertEq(0, _asset.balanceOf(address(aggregateToken)));
        assertEq(testParams.principal, _liquidVault.balanceOf(address(aggregateToken), testParams.depositPeriod));

        // invest assets
        uint256 investAmount = 2_000 * _scale;
        vm.prank(bob);
        _asset.transfer(address(_liquidVault), investAmount);

        //first redeem first
        _warpToPeriod(_liquidVault, testParams.redeemPeriod - _liquidVault.noticePeriod());

        vm.prank(NEST_ADMIN_ADDRESS);
        aggregateToken.requestSellComponentToken(IComponentToken(address(_liquidVault)), testParams.principal);

        _warpToPeriod(_liquidVault, testParams.redeemPeriod);

        vm.prank(NEST_ADMIN_ADDRESS);
        aggregateToken.sellComponentToken(IComponentToken(address(_liquidVault)), testParams.principal);

        uint256 expectedAmount = testParams.principal + _expectedReturns(0, _liquidVault, testParams);
        assertEq(expectedAmount, _asset.balanceOf(address(aggregateToken)));
    }
}
