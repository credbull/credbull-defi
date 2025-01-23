// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IVault } from "@credbull/token/ERC4626/IVault.sol";

import { TestParamSet } from "@test/test/token/ERC1155/TestParamSet.t.sol";

import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { TestUtil } from "@test/test/util/TestUtil.t.sol";

abstract contract IVaultTestSuite is TestUtil {
    using TestParamSet for TestParamSet.TestParam[];

    IERC20Metadata internal _asset;
    uint256 internal _scale;

    address internal _owner = makeAddr("owner");
    address internal _alice = makeAddr("alice");
    address internal _bob = makeAddr("bob");
    address internal _charlie = makeAddr("charlie");

    TestParamSet.TestParam internal _testParams1;
    TestParamSet.TestParam internal _testParams2;
    TestParamSet.TestParam internal _testParams3;

    function setUp() public virtual {
        vm.prank(_owner);
        _asset = new SimpleUSDC(_owner, 1_000_000 ether);
        _scale = 10 ** _asset.decimals();

        _transferAndAssert(_asset, _owner, _alice, 100_000 * _scale);

        _testParams1 = TestParamSet.TestParam({ principal: 500 * _scale, depositPeriod: 10, redeemPeriod: 21 });
        _testParams2 = TestParamSet.TestParam({ principal: 300 * _scale, depositPeriod: 15, redeemPeriod: 17 });
        _testParams3 = TestParamSet.TestParam({ principal: 700 * _scale, depositPeriod: 30, redeemPeriod: 55 });
    }

    // ========================= Test Suite =========================

    function test__IVaultSuite__DepositAndRedeem() public {
        _transferAndAssert(_asset, _owner, _charlie, 100_000 * _scale);

        testVaultAtOffsets(_charlie, _vault(), _testParams1);
    }

    function test__IVaultSuite__SimpleDeposit() public {
        IVault vault = _vault();

        address vaultAddress = address(vault);

        assertEq(0, _asset.allowance(_alice, vaultAddress), "vault shouldn't have an allowance to start");
        assertEq(0, _asset.balanceOf(vaultAddress), "vault shouldn't have a balance to start");

        vm.startPrank(_alice);
        _asset.approve(vaultAddress, _testParams1.principal);

        assertEq(_testParams1.principal, _asset.allowance(_alice, vaultAddress), "vault should have allowance");
        vm.stopPrank();

        vm.startPrank(_alice);
        vault.deposit(_testParams1.principal, _alice);
        vm.stopPrank();

        assertEq(_testParams1.principal, _asset.balanceOf(vaultAddress), "vault should have the asset");
        assertEq(0, _asset.allowance(_alice, vaultAddress), "vault shouldn't have an allowance after deposit");

        testVaultAtOffsets(_alice, vault, _testParams1);
    }

    function test__IVaultSuite__MultipleDepositsAndRedeem() public {
        IVault vault = _vault();

        TestParamSet.TestUsers memory testUsers = TestParamSet.toSingletonUsers(_alice);

        uint256 deposit1Shares = _testDepositOnly(testUsers, vault, _testParams1);
        uint256 deposit2Shares = _testDepositOnly(testUsers, vault, _testParams2);

        _warpToPeriod(vault, _testParams2.depositPeriod); // warp to deposit2Period

        // verify redeem - period 1
        uint256 deposit1ExpectedYield = _expectedReturns(deposit1Shares, vault, _testParams1);
        uint256 deposit1Assets = _testRedeemOnly(testUsers, vault, _testParams1, deposit1Shares);
        assertApproxEqAbs(
            _testParams1.principal + deposit1ExpectedYield,
            deposit1Assets,
            TOLERANCE,
            "deposit1 deposit assets incorrect"
        );

        // verify redeem - period 2
        uint256 deposit2Assets = _testRedeemOnly(testUsers, vault, _testParams2, deposit2Shares);
        assertApproxEqAbs(
            _testParams2.principal + _expectedReturns(deposit1Shares, vault, _testParams2),
            deposit2Assets,
            TOLERANCE,
            "deposit2 deposit assets incorrect"
        );

        testVaultAtOffsets(_alice, vault, _testParams1);
        testVaultAtOffsets(_alice, vault, _testParams2);
    }

    // ========================= Verifiers =========================

    function testVaultAtOffsets(address account, IVault vault, TestParamSet.TestParam memory testParam)
        internal
        virtual
        returns (uint256[] memory sharesAtPeriods_, uint256[] memory assetsAtPeriods_);

    /// @dev verify deposit.  updates vault assets and shares.
    function _testDepositOnly(
        TestParamSet.TestUsers memory depositUsers,
        IVault vault,
        TestParamSet.TestParam memory testParam
    ) internal virtual returns (uint256 actualSharesAtPeriod_);

    /// @dev verify redeem.  updates vault assets and shares.
    function _testRedeemOnly(
        TestParamSet.TestUsers memory redeemUsers,
        IVault vault,
        TestParamSet.TestParam memory testParam,
        uint256 sharesToRedeemAtPeriod
    ) internal virtual returns (uint256 actualAssetsAtPeriod_);

    /// @dev expected shares.  how much in assets should this vault give for the the deposit.
    function _expectedShares(IVault vault, TestParamSet.TestParam memory testParam)
        internal
        view
        virtual
        returns (uint256 expectedShares);

    /// @dev expected returns.  returns is the difference between the assets deposited (i.e. the principal) and the assets redeemed.
    function _expectedReturns(uint256 shares, IVault vault, TestParamSet.TestParam memory testParam)
        internal
        view
        virtual
        returns (uint256 expectedReturns_);

    /// @dev warp the vault to the given timePeriod for testing purposes
    /// @dev this assumes timePeriod is in days
    function _warpToPeriod(IVault vault, uint256 timePeriod) internal virtual;

    function _vault() internal virtual returns (IVault);
}
