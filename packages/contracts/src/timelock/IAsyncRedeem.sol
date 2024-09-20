// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ITimelockOpenEnded } from "@credbull/timelock/ITimelockOpenEnded.sol";

/**
 * @title IAsyncRedeem
 */
interface IAsyncRedeem is ITimelockOpenEnded {
    /// @notice Requests redemption of `shares` for assets, which will be transferred to `receiver` after the `redeemPeriod`.
    function requestRedeem(uint256 shares, address receiver, address owner, uint256 depositPeriod, uint256 redeemPeriod)
        external
        returns (uint256 assets);

    /// @notice Processes the redemption of `shares` for assets after the `redeemPeriod`, transferring to `receiver`.
    function redeem(uint256 shares, address receiver, address owner, uint256 depositPeriod, uint256 redeemPeriod)
        external
        returns (uint256 assets);
}
