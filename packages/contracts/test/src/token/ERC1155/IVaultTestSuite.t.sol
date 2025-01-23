// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IVault } from "@credbull/token/ERC4626/IVault.sol";

// TODO - remove this dependency.  only use IVault interface.
import { IMultiTokenVault } from "@credbull/token/ERC1155/IMultiTokenVault.sol";
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

    function test__MultiTokenVaultTest__DepositAndRedeem() public {
        uint256 assetToSharesRatio = 3;

        _transferAndAssert(_asset, _owner, _charlie, 100_000 * _scale);

        IMultiTokenVault vault = _createMultiTokenVault(_asset, assetToSharesRatio, 10);

        testVaultAtOffsets(_charlie, vault, _testParams1);
    }

    // ========================= interface =========================

    // TODO - change to return IVault and an IYield rather than current params.
    function _createMultiTokenVault(IERC20Metadata asset_, uint256 assetToSharesRatio, uint256 yieldPercentage)
        internal
        virtual
        returns (IMultiTokenVault);

    function testVaultAtOffsets(address account, IVault vault, TestParamSet.TestParam memory testParam)
        internal
        virtual
        returns (uint256[] memory sharesAtPeriods_, uint256[] memory assetsAtPeriods_);

    /// @dev test Vault at specified redeemPeriod and other "interesting" redeem periods
    function testVaultAtOffsets(
        TestParamSet.TestUsers memory depositUsers,
        TestParamSet.TestUsers memory redeemUsers,
        IVault vault,
        TestParamSet.TestParam memory testParam
    ) internal virtual returns (uint256[] memory sharesAtPeriods_, uint256[] memory assetsAtPeriods_);
}
