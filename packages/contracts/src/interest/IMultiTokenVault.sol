// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * @title IMultiTokenVault
 * @dev Vault supporting multiple deposit periods with independent returns and redemption rules.
 * Follows the IERC4626 convention - adding in support for multiple Tokens at given depositPeriods
 */
interface IMultiTokenVault is IERC1155 {
    error IMultiTokenVault__RedeemBeforeDeposit(address owner, uint256 depositPeriod, uint256 redeemPeriod);
    error IMultiTokenVault__RedeemPeriodNotSupported(address owner, uint256 currentPeriod, uint256 redeemPeriod);

    // =============== General utility view function ===============

    /**
     * @dev Calculates the amount of assets that can be withdrawn at the current time based on the shares minted at the time of `depositPeriod`.
     */
    function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod)
        external
        view
        returns (uint256 assets);

    /// @notice Converts `shares` to assets for `depositPeriod` and `redeemPeriod`.
    function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod, uint256 redeemPeriod)
        external
        view
        returns (uint256 assets);

    /**
     * @dev Converts `assets` to shares for `depositPeriod`.
     */
    function convertToSharesForDepositPeriod(uint256 assets, uint256 depositPeriod)
        external
        view
        returns (uint256 shares);

    /// @notice Converts `assets` to shares at the current period.
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    // =============== Deposit ===============

    /**
     * @dev Deposits assets into the vault and mints shares for the current time period.
     * Initially, assets and shares are equivalent.
     * @param assets The amount of asset to be deposited into the vault.
     * @param receiver The address that will receive the minted shares.
     * @return depositPeriod The current time period for the deposit, corresponding to the token ID in ERC1155.
     * @return shares The amount of ERC1155 tokens minted, where the `depositPeriod` acts as the token ID.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 depositPeriod, uint256 shares);

    // =============== Redeem/Withdraw ===============

    /// @notice Redeems `shares` for assets, transferring to `receiver`, for `depositPeriod` and `redeemPeriod`.
    function redeemForDepositPeriod(
        uint256 shares,
        address receiver,
        address owner,
        uint256 depositPeriod,
        uint256 redeemPeriod
    ) external returns (uint256 assets);

    /**
     * @dev Returns the shares minted at the time of `depositPeriod` to the vault,
     * allowing the corresponding assets to be redeemed.
     */
    function redeemForDepositPeriod(uint256 shares, address receiver, address owner, uint256 depositPeriod)
        external
        returns (uint256 assets);

    /**
     * @dev Returns the total amount of assets the user can withdraw from the vault at the moment.
     */
    function previewWithdraw(address user) external view returns (uint256 assets);

    /**
     * @dev The owner withdraws the assets deposited at the time of `depositPeriod`.
     */
    function withdrawForDepositPeriod(uint256 assets, address receiver, address owner, uint256 depositPeriod)
        external
        returns (uint256 shares);

    /**
     * @dev This function allows the owner to withdraw assets from the vault regardless of the depositPeriods.
     */
    function withdraw(uint256 assets, address receiver, address owner) external;

    // =============== Operational ===============

    /// @notice Returns the address of the underlying token.
    function asset() external view returns (address asset_);

    /// @notice Returns the shares held by `account` for `depositPeriod`.
    function sharesAtPeriod(address account, uint256 depositPeriod) external view returns (uint256 shares);

    /// @notice Returns the current number of time periods elapsed.
    function currentTimePeriodsElapsed() external view returns (uint256 currentTimePeriodsElapsed_);

    /**
     * @dev This function is for only testing purposes
     */
    function setCurrentTimePeriodsElapsed(uint256 currentTimePeriodsElapsed) external;
}
