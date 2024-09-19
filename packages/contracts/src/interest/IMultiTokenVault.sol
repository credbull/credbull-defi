// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

/**
 * @title IMultiTokenVault
 * @dev Vault supporting multiple deposit periods with independent returns and redemption rules.
 */
interface IMultiTokenVault {
    /// @notice Returns the yield for `principal` between `depositPeriod` and `redeemPeriod`.
    function calcYield(uint256 principal, uint256 depositPeriod, uint256 redeemPeriod)
        external
        view
        returns (uint256 yield);

    // =============== Deposit ===============

    /// @notice Converts `assets` to shares for `depositPeriod`.
    function convertToSharesForDepositPeriod(uint256 assets, uint256 depositPeriod)
        external
        view
        returns (uint256 shares);

    /// @notice Converts `assets` to shares at the current period.
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /// @notice Previews the deposit of `assets` at the current period.
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /// @notice Deposits `assets` and mints shares to `receiver`.
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    // =============== Redeem ===============

    /// @notice Converts `shares` to assets for `depositPeriod` and `redeemPeriod`.
    function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod, uint256 redeemPeriod)
        external
        view
        returns (uint256 assets);

    /// @notice Previews the redeem of `shares` for `depositPeriod` and `redeemPeriod`.
    function previewRedeemForDepositPeriod(uint256 shares, uint256 depositPeriod, uint256 redeemPeriod)
        external
        view
        returns (uint256 assets);

    /// @notice Redeems `shares` for assets, transferring to `receiver`, for `depositPeriod` and `redeemPeriod`.
    function redeemForDepositPeriod(
        uint256 shares,
        address receiver,
        address owner,
        uint256 depositPeriod,
        uint256 redeemPeriod
    ) external returns (uint256 assets);

    /// @notice Converts `shares` to assets for `depositPeriod` and the current redeem period.
    function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod)
        external
        view
        returns (uint256 assets);

    /// @notice Previews the redeem of `shares` for `depositPeriod` and the current redeem period.
    function previewRedeemForDepositPeriod(uint256 shares, uint256 depositPeriod)
        external
        view
        returns (uint256 assets);

    /// @notice Redeems `shares` for assets, transferring to `receiver`, for `depositPeriod` and the current redeem period.
    function redeemForDepositPeriod(uint256 shares, address receiver, address owner, uint256 depositPeriod)
        external
        returns (uint256 assets);

    // =============== Utility ===============

    /// @notice Returns the address of the underlying token.
    function getAsset() external view returns (IERC20 asset);

    /// @notice Returns the shares held by `account` for `depositPeriod`.
    function getSharesAtPeriod(address account, uint256 depositPeriod) external view returns (uint256 shares);

    /// @notice Returns the current number of time periods elapsed.
    function getCurrentTimePeriodsElapsed() external view returns (uint256 currentTimePeriodsElapsed);

    // =============== Operational ===============

    /// @notice Sets the current number of time periods elapsed (for testing purposes).
    // TODO lucasia - protect this with Access Control
    function setCurrentTimePeriodsElapsed(uint256 currentTimePeriodsElapsed) external;
}
