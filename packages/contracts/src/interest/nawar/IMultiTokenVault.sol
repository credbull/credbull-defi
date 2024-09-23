// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
/**
 * @title IMultiTokenVault
 */

interface IMultiTokenVault is IERC1155 {
    /**
     * @dev Returns the ERC20 underlying asset used in the vault
     * @return asset The ERC20 underlying asset
     */
    function getAsset() external view returns (IERC20 asset);

    /**
     * @dev Returns the current number of time periods elapsed
     */
    function getCurrentTimePeriodsElapsed() external view returns (uint256 currentTimePeriodsElapsed);

    /**
     * @dev Calculates the amount of assets that can be withdrawn at the current time based on the shares minted at the time of `depositPeriod`.
     */
    function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod)
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

    /**
     * @dev Returns the total amount of assets the user can withdraw from the vault at the moment.
     */
    function previewWithdraw(address user) external view returns (uint256 assets);

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

    // =============== Redeem ===============

    /**
     * @dev Returns the shares minted at the time of `depositPeriod` to the vault,
     * allowing the corresponding assets to be redeemed.
     */
    function redeemForDepositPeriod(uint256 shares, address receiver, address owner, uint256 depositPeriod)
        external
        returns (uint256 assets);

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
    /**
     * @dev This function is for only testing purposes
     */
    function setCurrentTimePeriodsElapsed(uint256 currentTimePeriodsElapsed) external;
}
