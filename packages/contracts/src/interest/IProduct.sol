// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ICalcInterestMetadata } from "@credbull/interest/ICalcInterestMetadata.sol";

interface IProduct is ICalcInterestMetadata {
    error RedeemTimePeriodNotSupported(address owner, uint256 period, uint256 redeemPeriod);

    // ===============  Vault / Vault-like Behavior ===============

    /// @notice Deposits `assets` and returns `shares` to `receiver`.
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /// @notice Redeems `shares` for assets, transferring to `receiver`.
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);

    /// @notice Redeems `shares` for assets based on `redeemTimePeriod`.
    function redeemAtPeriod(uint256 shares, address receiver, address owner, uint256 redeemTimePeriod)
        external
        returns (uint256 assets);

    /// @notice Returns interest accrued for `account` at `depositTimePeriod`.
    function calcInterestForDepositTimePeriod(address account, uint256 depositTimePeriod)
        external
        view
        returns (uint256);

    /// @notice Returns total interest accrued by `account`.
    function calcTotalInterest(address account) external view returns (uint256);

    /// @notice Returns total assets deposited by `account`.
    function calcTotalDeposits(address account) external view returns (uint256);

    // =============== Testing Purposes Only ===============

    /// @notice Sets the number of time periods elapsed (for testing).
    function setCurrentTimePeriodsElapsed(uint256 currentTimePeriodsElapsed) external;
}
