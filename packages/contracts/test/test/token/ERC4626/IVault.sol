// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IVault
 * @dev ERC4626 Vault-like interface
 */
interface IVault {
    /// @notice token used for depositing and withdrawing
    function asset() external view returns (address asset_);

    /// @notice amount of shares vault would exchange for the amount of assets in an ideal situation
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /// @notice mints shares in the vault by depositing the given number of assets
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    // MultiToken variant MUST return the balanceOf for the `depositPeriod`
    // Single Token variant MUST return the 'logical' shares for the period (e.g. considering locks)
    function sharesAtPeriod(address owner, uint256 depositPeriod) external view returns (uint256 shares);

    // MultiToken variant MUST redeem at the given `depositPeriod`
    // Single Token variant MUST redeem the 'logical' shares for the period (e.g. considering locks)
    function redeemForDepositPeriod(uint256 shares, address receiver, address owner, uint256 depositPeriod)
        external
        returns (uint256 assets);

    /// @notice get current number of time periods elapsed
    function currentPeriodsElapsed() external view returns (uint256 currentPeriodsElapsed_);
}
