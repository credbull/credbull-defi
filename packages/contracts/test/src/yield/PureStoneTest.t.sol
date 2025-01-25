// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { PureStone } from "@credbull/yield/PureStone.sol";

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
        _tenor = _pureStone._tenor();

        init(_pureStone, _pureStoneVerifier);
    }

    function test__PureStone__SimpleDepositAndRedeem() public {
        (TestParamSet.TestUsers memory depositUsers, TestParamSet.TestUsers memory redeemUsers) =
            _pureStoneVerifier._createTestUsers(_alice);

        TestParamSet.TestParam[] memory testParams = new TestParamSet.TestParam[](1);
        testParams[0] = TestParamSet.TestParam({ principal: 100 * _scale, depositPeriod: 0, redeemPeriod: 5 });

        uint256[] memory sharesAtPeriods =
            _pureStoneVerifier._verifyDepositOnlyBatch(depositUsers, _pureStone, testParams);
        _pureStoneVerifier._verifyRedeemOnlyBatch(redeemUsers, _pureStone, testParams, sharesAtPeriods);
    }

    // TODO - add in an equivalent batch redeem and deposit test.  PureStone redeems need to be exactly at tenor.
    // [FAIL: PureStone__InvalidRedeemForDepositPeriod(0x208f3fE250d3c6A20C248962884AC5052d63e6F9, 0x208f3fE250d3c6A20C248962884AC5052d63e6F9, 0, 31)]
    function test__IVaultSuite__DepositBatchRedeemOnTenor2() public override {
        vm.skip(true);
    }

    // TODO - need to implement this
    function test__PureStone__MaxUnlockTenorMods() public {
        vm.skip(true);
        uint256 depositPeriod = 5;
        uint256 redeemPeriod = depositPeriod + _pureStone._tenor();

        TestParamSet.TestUsers memory aliceTestUsers = TestParamSet.toSingletonUsers(_alice);

        TestParamSet.TestParam[] memory testParams = new TestParamSet.TestParam[](3);
        testParams[0] = TestParamSet.TestParam({
            principal: 100 * _scale,
            depositPeriod: depositPeriod,
            redeemPeriod: redeemPeriod
        });
        testParams[1] = TestParamSet.TestParam({
            principal: 200 * _scale,
            depositPeriod: 2 * depositPeriod,
            redeemPeriod: 2 * redeemPeriod
        });
        testParams[2] = TestParamSet.TestParam({
            principal: 200 * _scale,
            depositPeriod: 3 * depositPeriod,
            redeemPeriod: 3 * redeemPeriod
        });

        _pureStoneVerifier._verifyDepositOnlyBatch(aliceTestUsers, _pureStone, testParams);

        _pureStoneVerifier._warpToPeriod(_pureStone, testParams[0].redeemPeriod);
        assertEq(
            testParams[0].principal, _pureStone.maxUnlock(_alice, _pureStone.currentPeriod()), "max unlock period 1"
        );

        // TODO - need to implement logic to either calculate previous periods or roll-over
        // warp to period 2 - should include period 1 and 2
        _pureStoneVerifier._warpToPeriod(_pureStone, testParams[0].redeemPeriod);
        assertEq(
            testParams[0].principal + testParams[1].principal,
            _pureStone.maxUnlock(_alice, _pureStone.currentPeriod()),
            "max unlock period 2"
        );
    }

    function _createPureStone(IERC20Metadata asset_, uint256 yieldPercentage) internal virtual returns (PureStone) {
        PureStone.PureStoneParams memory params = PureStone.PureStoneParams({
            name: "TEST Credbull PureStone",
            symbol: "TEST_CPS",
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
