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
    TestParamFactory private _testParamFactory;

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

    // deposit on day 0
    function test__IVaultSuite__DepositDay0AndRedeemBeforeTenor() public {
        verify(_alice, _testParamFactory.depositOnZeroRedeemPreTenor());
    }

    function test__IVaultSuite__DepositDay0AndRedeemAtTenor() public {
        verify(_alice, _testParamFactory.depositOnZeroRedeemOnTenor());
    }

    function test__IVaultSuite__DepositDay0AndRedeemAfterTenor() public {
        verify(_alice, _testParamFactory.depositOnZeroRedeemPostTenor());
    }

    // deposit on day 1
    function test__IVaultSuite__DepositDay1AndRedeemBeforeTenor() public {
        verify(_alice, _testParamFactory.depositOnOneRedeemPreTenor());
    }

    function test__IVaultSuite__DepositDay1AndRedeemAtTenor() public {
        verify(_alice, _testParamFactory.depositOnOneRedeemOnTenor());
    }

    function test__IVaultSuite__DepositDay1AndRedeemAfterTenor() public {
        verify(_alice, _testParamFactory.depositOnOneRedeemPostTenor());
    }

    // deposit tenor - 1
    function test__IVaultSuite__DepositBeforeTenorAndRedeemBeforeTenor() public virtual {
        verify(_alice, _testParamFactory.depositPreTenorRedeemPreTenor());
    }

    function test__IVaultSuite__DepositBeforeTenorAndRedeemAtTenor() public {
        verify(_alice, _testParamFactory.depositPreTenorRedeemOnTenor());
    }

    function test__IVaultSuite__DepositBeforeTenorAndRedeemAfterTenor() public {
        verify(_alice, _testParamFactory.depositPreTenorRedeemPostTenor());
    }

    // deposit on tenor
    function test__IVaultSuite__DepositOnTenorAndRedeemBeforeTenor2() public {
        verify(_alice, _testParamFactory.depositOnTenorRedeemPreTenor2());
    }

    function test__IVaultSuite__DepositOnTenorAndRedeemAtTenor2() public {
        verify(_alice, _testParamFactory.depositOnTenorRedeemOnTenor2());
    }

    function test__IVaultSuite__DepositOnTenorAndRedeemAfterTenor2() public {
        verify(_alice, _testParamFactory.depositOnTenorRedeemPostTenor2());
    }

    // deposit on tenor + 1
    function test__IVaultSuite__DepositAfterTenorAndRedeemBeforeTenor2() public {
        verify(_alice, _testParamFactory.depositPostTenorRedeemPreTenor2());
    }

    function test__IVaultSuite__DepositAfterTenorAndRedeemAtTenor2() public {
        verify(_alice, _testParamFactory.depositPostTenorRedeemOnTenor2());
    }

    function test__IVaultSuite__DepositAfterTenorAndRedeemAfterTenor2() public {
        verify(_alice, _testParamFactory.depositPostTenorRedeemPostTenor2());
    }

    // ======================================================================================
    // multiple deposit and redeem
    // ======================================================================================

    function test__IVaultSuite__MultipleDepositsAndRedeem() public virtual {
        TestParamSet.TestParam memory testParams1 =
            TestParamSet.TestParam({ principal: 500 * _scale, depositPeriod: 10, redeemPeriod: 21 });
        TestParamSet.TestParam memory testParams2 =
            TestParamSet.TestParam({ principal: 300 * _scale, depositPeriod: 15, redeemPeriod: 17 });

        IVault vault = _vault;

        TestParamSet.TestUsers memory testUsers = TestParamSet.toSingletonUsers(_alice);

        uint256 deposit1Shares = _verifier._verifyDepositOnly(testUsers, vault, testParams1);
        uint256 deposit2Shares = _verifier._verifyDepositOnly(testUsers, vault, testParams2);

        _verifier._warpToPeriod(vault, testParams2.depositPeriod); // warp to deposit2Period

        // verify redeem - period 1
        uint256 deposit1ExpectedAssets = _verifier._expectedAssets(vault, testParams1);
        uint256 deposit1Assets = _verifier._verifyRedeemOnly(testUsers, vault, testParams1, deposit1Shares);
        assertApproxEqAbs(deposit1ExpectedAssets, deposit1Assets, TOLERANCE, "deposit1 deposit assets incorrect");

        // verify redeem - period 2
        uint256 deposit2ExpectedAssets = _verifier._expectedAssets(vault, testParams2);
        uint256 deposit2Assets = _verifier._verifyRedeemOnly(testUsers, vault, testParams2, deposit2Shares);
        assertApproxEqAbs(deposit2ExpectedAssets, deposit2Assets, TOLERANCE, "deposit2 deposit assets incorrect");

        _verifier.verifyVaultAtOffsets(_alice, vault, testParams1);
        _verifier.verifyVaultAtOffsets(_alice, vault, testParams2);
    }

    function verify(address account, TestParamSet.TestParam memory testParam) public {
        (TestParamSet.TestUsers memory depositUsers, TestParamSet.TestUsers memory redeemUsers) =
            _verifier._createTestUsers(account);

        TestParamSet.TestParam[] memory testParams = new TestParamSet.TestParam[](1);
        testParams[0] = testParam;

        uint256[] memory sharesAtPeriods = _verifier._verifyDepositOnly(depositUsers, _vault, testParams);
        _verifier._verifyRedeemOnly(redeemUsers, _vault, testParams, sharesAtPeriods);
    }
}
