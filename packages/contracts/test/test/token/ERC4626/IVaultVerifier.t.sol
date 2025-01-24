// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IVault } from "@credbull/token/ERC4626/IVault.sol";
import { TestParamSet } from "@test/test/token/ERC1155/TestParamSet.t.sol";

interface IVaultVerifier {
    function verifyVaultAtOffsets(address account, IVault vault, TestParamSet.TestParam memory testParam)
        external
        returns (uint256[] memory sharesAtPeriods_, uint256[] memory assetsAtPeriods_);

    /// @dev verify deposit.  updates vault assets and shares.
    function _verifyDepositOnly(
        TestParamSet.TestUsers memory depositUsers,
        IVault vault,
        TestParamSet.TestParam[] memory testParams
    ) external returns (uint256[] memory sharesAtPeriod_);

    /// @dev verify deposit.  updates vault assets and shares.
    function _verifyDepositOnly(
        TestParamSet.TestUsers memory depositUsers,
        IVault vault,
        TestParamSet.TestParam memory testParam
    ) external returns (uint256 actualSharesAtPeriod_);

    /// @dev verify redeem.  updates vault assets and shares.
    function _verifyRedeemOnly(
        TestParamSet.TestUsers memory redeemUsers,
        IVault vault,
        TestParamSet.TestParam[] memory testParams,
        uint256[] memory sharesAtPeriods
    ) external returns (uint256[] memory assetsAtPeriods_);

    /// @dev verify redeem.  updates vault assets and shares.
    function _verifyRedeemOnly(
        TestParamSet.TestUsers memory redeemUsers,
        IVault vault,
        TestParamSet.TestParam memory testParam,
        uint256 sharesToRedeemAtPeriod
    ) external returns (uint256 actualAssetsAtPeriod_);

    /// @dev expected shares.  how much in assets should this vault give for the the deposit.
    function _expectedShares(IVault vault, TestParamSet.TestParam memory testParam)
        external
        view
        returns (uint256 expectedShares);

    /// @dev expected assets.  returns the assets deposited (i.e. the principal) plus any returns.
    // NB - this uses the testParam principal (rather than using the shares)
    function _expectedAssets(IVault vault, TestParamSet.TestParam memory testParam)
        external
        view
        returns (uint256 expectedAssets_);

    /// @dev expected returns.  returns is the difference between the assets deposited (i.e. the principal) and the assets redeemed.
    // NB - this uses the testParam principal (rather than using the shares)
    function _expectedReturns(IVault vault, TestParamSet.TestParam memory testParam)
        external
        view
        returns (uint256 expectedReturns_);

    /// @dev create users for testing
    function _createTestUsers(address account)
        external
        returns (TestParamSet.TestUsers memory depositUsers_, TestParamSet.TestUsers memory redeemUsers_);

    /// @dev warp the vault to the given timePeriod for testing purposes
    /// @dev this assumes timePeriod is in days
    function _warpToPeriod(IVault vault, uint256 timePeriod) external;
}
