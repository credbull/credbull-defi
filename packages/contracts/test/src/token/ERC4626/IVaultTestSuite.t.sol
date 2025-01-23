// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IVault } from "@credbull/token/ERC4626/IVault.sol";

import { IVaultVerifier } from "@test/test/token/ERC4626/IVaultVerifier.t.sol";
import { TestParamSet } from "@test/test/token/ERC1155/TestParamSet.t.sol";

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { TestUtil } from "@test/test/util/TestUtil.t.sol";

abstract contract IVaultTestSuite is TestUtil {
    using TestParamSet for TestParamSet.TestParam[];

    IVault private _iVault;
    IVaultVerifier private _iVerifier;

    IERC20Metadata internal _asset;
    uint256 internal _scale;

    // child classes should call to init in their setUp()
    function setUp() public virtual;

    // child classes should call to init in their setUp()
    function init(IVault vault, IVaultVerifier verifier) public {
        _iVault = vault;
        _iVerifier = verifier;
        _asset = IERC20Metadata(_iVault.asset());
        _scale = 10 ** _asset.decimals();

        _transferAndAssert(_asset, _owner, _alice, 100_000 * _scale);
        _transferAndAssert(_asset, _owner, _bob, 100_000 * _scale);
        _transferAndAssert(_asset, _owner, _charlie, 100_000 * _scale);
    }

    function test__IVaultSuite__DepositAndRedeem() public {
        TestParamSet.TestParam memory testParams =
            TestParamSet.TestParam({ principal: 100 * _scale, depositPeriod: 1, redeemPeriod: 11 });
        _iVerifier.verifyVaultAtOffsets(_charlie, _iVault, testParams);
    }

    function test__IVaultSuite__SimpleDeposit() public {
        TestParamSet.TestParam memory testParams =
            TestParamSet.TestParam({ principal: 200 * _scale, depositPeriod: 2, redeemPeriod: 22 });
        IVault vault = _iVault;

        address vaultAddress = address(vault);

        assertEq(0, _asset.allowance(_alice, vaultAddress), "vault shouldn't have an allowance to start");
        assertEq(0, _asset.balanceOf(vaultAddress), "vault shouldn't have a balance to start");

        vm.startPrank(_alice);
        _asset.approve(vaultAddress, testParams.principal);

        assertEq(testParams.principal, _asset.allowance(_alice, vaultAddress), "vault should have allowance");
        vm.stopPrank();

        vm.startPrank(_alice);
        vault.deposit(testParams.principal, _alice);
        vm.stopPrank();

        assertEq(testParams.principal, _asset.balanceOf(vaultAddress), "vault should have the asset");
        assertEq(0, _asset.allowance(_alice, vaultAddress), "vault shouldn't have an allowance after deposit");

        _iVerifier.verifyVaultAtOffsets(_alice, vault, testParams);
    }

    function test__IVaultSuite__MultipleDepositsAndRedeem() public {
        TestParamSet.TestParam memory testParams1 =
            TestParamSet.TestParam({ principal: 500 * _scale, depositPeriod: 10, redeemPeriod: 21 });
        TestParamSet.TestParam memory testParams2 =
            TestParamSet.TestParam({ principal: 300 * _scale, depositPeriod: 15, redeemPeriod: 17 });

        IVault vault = _iVault;

        TestParamSet.TestUsers memory testUsers = TestParamSet.toSingletonUsers(_alice);

        uint256 deposit1Shares = _iVerifier._verifyDepositOnly(testUsers, vault, testParams1);
        uint256 deposit2Shares = _iVerifier._verifyDepositOnly(testUsers, vault, testParams2);

        _iVerifier._warpToPeriod(vault, testParams2.depositPeriod); // warp to deposit2Period

        // verify redeem - period 1
        uint256 deposit1ExpectedYield = _iVerifier._expectedReturns(deposit1Shares, vault, testParams1);
        uint256 deposit1Assets = _iVerifier._verifyRedeemOnly(testUsers, vault, testParams1, deposit1Shares);
        assertApproxEqAbs(
            testParams1.principal + deposit1ExpectedYield,
            deposit1Assets,
            TOLERANCE,
            "deposit1 deposit assets incorrect"
        );

        // verify redeem - period 2
        uint256 deposit2Assets = _iVerifier._verifyRedeemOnly(testUsers, vault, testParams2, deposit2Shares);
        assertApproxEqAbs(
            testParams2.principal + _iVerifier._expectedReturns(deposit1Shares, vault, testParams2),
            deposit2Assets,
            TOLERANCE,
            "deposit2 deposit assets incorrect"
        );

        _iVerifier.verifyVaultAtOffsets(_alice, vault, testParams1);
        _iVerifier.verifyVaultAtOffsets(_alice, vault, testParams2);
    }
}
