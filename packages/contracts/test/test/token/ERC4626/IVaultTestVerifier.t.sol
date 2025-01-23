// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IVault } from "@credbull/token/ERC4626/IVault.sol";
import { TestParamSet } from "@test/test/token/ERC1155/TestParamSet.t.sol";

abstract contract IVaultTestVerifier {
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
