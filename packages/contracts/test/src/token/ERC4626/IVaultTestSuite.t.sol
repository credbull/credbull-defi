// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IVault } from "@credbull/token/ERC4626/IVault.sol";

import { IVaultVerifier } from "@test/test/token/ERC4626/IVaultVerifier.t.sol";
import { TestParamSet } from "@test/test/token/ERC1155/TestParamSet.t.sol";

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { TestParamFactory } from "@test/test/util/TestParamFactory.t.sol";
import { TestUtil } from "@test/test/util/TestUtil.t.sol";

abstract contract IVaultTestSuite is TestUtil {
    using TestParamSet for TestParamSet.TestParam[];

    IVault private _vault;
    IVaultVerifier private _verifier;
    TestParamFactory internal _testParamFactory;

    IERC20Metadata internal _asset;
    uint256 internal _scale;
    uint256 internal _tenor = 30; // common tenor for 360 day frequency

    function setUp() public virtual; // child classes should call to init in their setUp()

    // child classes should call to init in their setUp()
    function init(IVault vault, IVaultVerifier verifier) public {
        _vault = vault;
        _verifier = verifier;
        _asset = IERC20Metadata(_vault.asset());
        _scale = 10 ** _asset.decimals();

        // Initialize the factory with tenor and scale
        _testParamFactory = new TestParamFactory(_tenor, _scale);

        _transferAndAssert(_asset, _owner, _alice, 100_000 * _scale);
        _transferAndAssert(_asset, _owner, _bob, 100_000 * _scale);
        _transferAndAssert(_asset, _owner, _charlie, 100_000 * _scale);
    }

    // ======================================================================================
    // separate tests to help debug any failures. verbose but clearer test reporting.
    // ======================================================================================

    // deposit on zero
    function test__IVaultSuite__DepositOnZeroRedeemPreTenor() public {
        verify(_alice, _testParamFactory.depositOnZeroRedeemPreTenor());
    }

    function test__IVaultSuite__DepositOnZeroRedeemOnTenor() public {
        verify(_alice, _testParamFactory.depositOnZeroRedeemOnTenor());
    }

    function test__IVaultSuite__DepositOnZeroRedeemPostTenor() public {
        verify(_alice, _testParamFactory.depositOnZeroRedeemPostTenor());
    }

    // deposit on one
    function test__IVaultSuite__DepositOnOneRedeemPreTenor() public {
        verify(_alice, _testParamFactory.depositOnOneRedeemPreTenor());
    }

    function test__IVaultSuite__DepositOnOneRedeemOnTenor() public {
        verify(_alice, _testParamFactory.depositOnOneRedeemOnTenor());
    }

    function test__IVaultSuite__DepositOnOneRedeemPostTenor() public {
        verify(_alice, _testParamFactory.depositOnOneRedeemPostTenor());
    }

    // deposit before tenor
    function test__IVaultSuite__DepositPreTenorRedeemPreTenor() public virtual {
        verify(_alice, _testParamFactory.depositPreTenorRedeemPreTenor());
    }

    function test__IVaultSuite__DepositPreTenorRedeemOnTenor() public {
        verify(_alice, _testParamFactory.depositPreTenorRedeemOnTenor());
    }

    function test__IVaultSuite__DepositPreTenorRedeemPostTenor() public {
        verify(_alice, _testParamFactory.depositPreTenorRedeemPostTenor());
    }

    // deposit on tenor
    function test__IVaultSuite__DepositOnTenorRedeemPreTenor2() public {
        verify(_alice, _testParamFactory.depositOnTenorRedeemPreTenor2());
    }

    function test__IVaultSuite__DepositOnTenorRedeemOnTenor2() public {
        verify(_alice, _testParamFactory.depositOnTenorRedeemOnTenor2());
    }

    function test__IVaultSuite__DepositOnTenorRedeemPostTenor2() public {
        verify(_alice, _testParamFactory.depositOnTenorRedeemPostTenor2());
    }

    // deposit after tenor
    function test__IVaultSuite__DepositPostTenorRedeemPreTenor2() public {
        verify(_alice, _testParamFactory.depositPostTenorRedeemPreTenor2());
    }

    function test__IVaultSuite__DepositPostTenorRedeemOnTenor2() public {
        verify(_alice, _testParamFactory.depositPostTenorRedeemOnTenor2());
    }

    function test__IVaultSuite__DepositPostTenorRedeemPostTenor2() public {
        verify(_alice, _testParamFactory.depositPostTenorRedeemPostTenor2());
    }

    // ======================================================================================
    // multiple deposit and redeem
    // ======================================================================================

    // TODO - refactor this to use the batch versions...
    function test__IVaultSuite__MultipleDepositsAndRedeem() public virtual {
        IVault vault = _vault;

        TestParamSet.TestParam[] memory testParams = new TestParamSet.TestParam[](2);
        testParams[0] = TestParamSet.TestParam({ principal: 500 * _scale, depositPeriod: 10, redeemPeriod: 21 });
        testParams[1] = TestParamSet.TestParam({ principal: 300 * _scale, depositPeriod: 15, redeemPeriod: 17 });

        TestParamSet.TestUsers memory testUsers = TestParamSet.toSingletonUsers(_alice);

        uint256[] memory sharesAtPeriods = _verifier._verifyDepositOnly(testUsers, vault, testParams);
        assertEq(2, sharesAtPeriods.length, "expected two sharesAtPeriods");

        // TODO - warp probably not required here...
        // _verifier._warpToPeriod(vault, testParams[1].depositPeriod); // warp to deposit2Period

        uint256[] memory assetsAtPeriods = _verifier._verifyRedeemOnly(testUsers, vault, testParams, sharesAtPeriods);
        assertEq(2, sharesAtPeriods.length, "expected two assetsAtPeriods");

        // verify redeem - period 1
        uint256 deposit1ExpectedAssets = _verifier._expectedAssets(vault, testParams[0]);
        assertApproxEqAbs(deposit1ExpectedAssets, assetsAtPeriods[0], TOLERANCE, "deposit1 deposit assets incorrect");

        // verify redeem - period 2
        uint256 deposit2ExpectedAssets = _verifier._expectedAssets(vault, testParams[1]);
        assertApproxEqAbs(deposit2ExpectedAssets, assetsAtPeriods[1], TOLERANCE, "deposit2 deposit assets incorrect");

        _verifier.verifyVaultAtOffsets(_alice, vault, testParams[0]);
        _verifier.verifyVaultAtOffsets(_alice, vault, testParams[1]);
    }

    function verify(address account, TestParamSet.TestParam memory testParam) public {
        verify(account, TestParamSet.toSingletonArray(testParam));
    }

    function verify(address account, TestParamSet.TestParam[] memory testParams) public {
        (TestParamSet.TestUsers memory depositUsers, TestParamSet.TestUsers memory redeemUsers) =
            _verifier._createTestUsers(account);

        // TODO - use this version instead - but failing!
        //_verifier.verifyVault(depositUsers, redeemUsers, _vault, testParams);

        uint256[] memory sharesAtPeriods = _verifier._verifyDepositOnly(depositUsers, _vault, testParams);
        _verifier._verifyRedeemOnly(redeemUsers, _vault, testParams, sharesAtPeriods);
    }
}
