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

    // for MultiToken and similar will combine deposits and try to redeem together
    // see IMultiTokenVaultVerifierBase._testVaultCombineDepositsForRedeem()
    function test__IVaultSuite__DepositBatchRedeemOnTenor2() public virtual {
        TestParamSet.TestParam[] memory testParams = new TestParamSet.TestParam[](5);
        // multi-token : deposit group 1
        testParams[0] = _testParamFactory.depositOnZeroRedeemPostTenor();
        testParams[1] = _testParamFactory.depositOnOneRedeemPostTenor();
        testParams[2] = _testParamFactory.depositPreTenorRedeemPostTenor();
        // multi-token : deposit group 2
        testParams[3] = _testParamFactory.depositOnTenorRedeemOnTenor2();
        testParams[4] = _testParamFactory.depositPostTenorRedeemOnTenor2();

        verifyBatch(_alice, testParams);
    }

    function verify(address account, TestParamSet.TestParam memory testParam) public {
        verifyBatch(account, TestParamSet.toSingletonArray(testParam));
    }

    function verifyBatch(address account, TestParamSet.TestParam[] memory testParams) public {
        (TestParamSet.TestUsers memory depositUsers, TestParamSet.TestUsers memory redeemUsers) =
            _verifier._createTestUsers(account);

        _verifier.verifyVaultBatch(depositUsers, redeemUsers, _vault, testParams);
    }
}
