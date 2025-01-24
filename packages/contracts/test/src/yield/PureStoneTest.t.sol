// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { PureStone } from "@credbull/yield/PureStone.sol";
import { DiscountVault } from "@credbull/token/ERC4626/DiscountVault.sol";

import { IYieldStrategy } from "@credbull/yield/strategy/IYieldStrategy.sol";
import { SimpleInterestYieldStrategy } from "@credbull/yield/strategy/SimpleInterestYieldStrategy.sol";
import { IVaultTestSuite } from "@test/src/token/ERC4626/IVaultTestSuite.t.sol";

import { PureStoneVerifier } from "@test/test/yield/PureStoneVerifier.t.sol";
import { TestParamSet } from "@test/test/token/ERC1155/TestParamSet.t.sol";

contract PureStoneTest is IVaultTestSuite {
    using TestParamSet for TestParamSet.TestParam[];

    PureStone private _pureStone;
    PureStoneVerifier private _pureStoneVerifier;
    IYieldStrategy private _yieldStrategy;

    TestParamSet.TestParam internal _testParams1;

    function setUp() public override {
        _yieldStrategy = new SimpleInterestYieldStrategy();
        _pureStone = _createPureStone(_createAsset(_owner), 10);
        _pureStoneVerifier = new PureStoneVerifier();
        _testParams1 = TestParamSet.TestParam({ principal: 500 * _scale, depositPeriod: 10, redeemPeriod: 40 });

        init(_pureStone, _pureStoneVerifier);
    }

    function test__PureStone__SimpleDepositAndRedeem() public {
        (TestParamSet.TestUsers memory depositUsers, TestParamSet.TestUsers memory redeemUsers) =
            _pureStoneVerifier._createTestUsers(_alice);

        TestParamSet.TestParam[] memory testParams = new TestParamSet.TestParam[](1);
        testParams[0] = TestParamSet.TestParam({ principal: 100 * _scale, depositPeriod: 0, redeemPeriod: 5 });

        uint256[] memory sharesAtPeriods = _pureStoneVerifier._verifyDepositOnly(depositUsers, _pureStone, testParams);
        _pureStoneVerifier._verifyRedeemOnly(redeemUsers, _pureStone, testParams, sharesAtPeriods);
    }

    function _createPureStone(IERC20Metadata asset_, uint256 yieldPercentage) internal virtual returns (PureStone) {
        DiscountVault.DiscountVaultParams memory params = DiscountVault.DiscountVaultParams({
            asset: asset_,
            yieldStrategy: _yieldStrategy,
            ratePercentageScaled: yieldPercentage * _scale,
            frequency: 360,
            vaultStartTimestamp: 0,
            tenor: 30
        });

        PureStone vaultImpl = new PureStone();
        PureStone vaultProxy = PureStone(
            address(new ERC1967Proxy(address(vaultImpl), abi.encodeWithSelector(vaultImpl.initialize.selector, params)))
        );

        return vaultProxy;
    }
}
