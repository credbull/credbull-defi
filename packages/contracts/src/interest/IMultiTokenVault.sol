// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * @title IMultiTokenVault
 */
interface IMultiTokenVault is IERC1155 {
    error IMultiTokenVault__RedeemBeforeDeposit(address owner, uint256 depositPeriod, uint256 redeemPeriod);
    error IMultiTokenVault__RedeemPeriodNotSupported(address owner, uint256 currentPeriod, uint256 redeemPeriod);

    event Deposit(
        address indexed sender, address indexed receiver, uint256 depositPeriod, uint256 assets, uint256 shares
    );

    event Withdraw(
        address indexed sender, address indexed receiver, address indexed owner, uint256 assets, uint256 shares
    );

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 depositPeriod,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the ERC-20 underlying asset address used in the vault.
     *
     * @return asset The ERC-20 underlying asset address.
     */
    function asset() external view returns (address);

    /**
     * @dev Returns the total amount of the underlying asset that is held by vault.
     *
     * @return totalAssets The total amount of the underlying asset.
     */
    function totalAssets() external view returns (uint256 totalAssets);

    // =============== General utility view function ===============

    /**
     * @dev Converts shares to assets for deposit period at the current redeem period.
     *
     * @return assets The equivalent amount of the underlying asset.
     */
    function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod)
        external
        view
        returns (uint256 assets);

    /**
     * @dev Converts shares to assets for deposit period and redeem period.
     *
     * @return assets The equivalent amount of the underlying asset.
     */
    function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod, uint256 redeemPeriod)
        external
        view
        returns (uint256 assets);

    /**
     * @dev Converts assets to shares for the deposit period.
     *
     * @return shares The equivalent amount of shares.
     */
    function convertToSharesForDepositPeriod(uint256 assets, uint256 depositPeriod)
        external
        view
        returns (uint256 shares);

    /**
     * @dev Converts assets to shares at the current period.
     *
     * @return shares The equivalent amount of shares.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    // =============== Deposit ===============

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the vault for the receiver at the deposit period.
     *
     * @param receiver The user who wants to deposit.
     * @param depositPeriod The deposit period to deposit at.
     *
     * @return maxAssets The maximum amount of the underlying asset can be deposited.
     */
    function maxDepositAtPeriod(address receiver, uint256 depositPeriod) external view returns (uint256 maxAssets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the vault for the receiver at the current deposit period.
     *
     * @param receiver The user who wants to deposit.
     *
     * @return maxAssets The maximum amount of the underlying asset can be deposited.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Simulate the deposit of the underlying assets into the vault and return the equivalent amount of shares for the current time period.
     *
     * @param assets The current time period for the deposit, corresponding to the token ID in ERC1155.
     *
     * @return depositPeriod The current time period for the deposit, corresponding to the token ID in ERC-1155.
     * @return shares The amount of ERC-1155 tokens minted.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 depositPeriod, uint256 shares);

    /**
     * @dev Deposits assets into the vault and mints shares for the current time period.
     * Initially, assets and shares are equivalent.
     *
     * @param assets The amount of asset to be deposited into the vault.
     * @param receiver The address that will receive the minted shares.
     *
     * @return depositPeriod The current time period for the deposit, corresponding to the token ID in ERC-1155.
     * @return shares The amount of ERC-1155 tokens minted.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 depositPeriod, uint256 shares);

    // =============== Redeem/Withdraw ===============

    /**
     * @dev Returns the amount of assets that will be redeemed for a given amount of shares at a specific period of time.
     *
     * @param shares The amount of shares to redeem.
     * @param depositPeriod The deposit period in which the shares were issued.
     *
     * @return assets The amount of assets that will be redeemed for the given shares.
     */
    function previewRedeemForDepositPeriod(uint256 shares, uint256 depositPeriod)
        external
        view
        returns (uint256 assets);

    /**
     * @dev Redeems the shares minted at the time of the deposit period from the vault to the owner, while the redemption happens at the defined redeem period
     * And return the equivalent amount of assets to the receiver.
     *
     * @param shares The amount of shares to be redeemed from the vault.
     * @param receiver The address that will receive the minted shares.
     * @param owner The address that owns the minted shares.
     * @param depositPeriod The related time period that the assets has deposited at, represents the ERC-1155 token ID.
     * @param redeemPeriod The period of time to be redeemed at.
     *
     * @return assets The amount of equivalent assets to get.
     */
    function redeemForDepositPeriod(
        uint256 shares,
        address receiver,
        address owner,
        uint256 depositPeriod,
        uint256 redeemPeriod
    ) external returns (uint256 assets);

    /**
     * @dev Redeems the shares minted at the time of the deposit period from the vault to the owner, while the redemption happens at the current redeem period
     * And return the equivalent amount of assets to the receiver.
     *
     * @param shares The amount of shares to be redeemed from the vault.
     * @param receiver The address that will receive the minted shares.
     * @param owner The address that owns the minted shares.
     * @param depositPeriod The related time period that the assets has deposited at, represents the ERC-1155 token ID.
     *
     * @return assets The amount of equivalent assets to get.
     */
    function redeemForDepositPeriod(uint256 shares, address receiver, address owner, uint256 depositPeriod)
        external
        returns (uint256 assets);

    /**
     * @dev Redeems the total amount of shares minted from the vault to the owner, while the redemption happens at the current redeem period
     * And return the equivalent amount of assets to the receiver.
     *
     * @param shares The amount of shares to be redeemed from the vault.
     * @param receiver The address that will receive the minted shares.
     * @param owner The address that owns the minted shares.
     *
     * @return assets The amount of equivalent assets to get.
     */
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);

    /**
     * @dev Returns the total amount of assets the user can withdraw from the vault.
     *
     * @param receiver The address of shares to be redeemed from the vault.
     *
     * @return assets The total amount of underlying assets that user can withdraw.
     */
    function previewWithdraw(address receiver) external view returns (uint256 assets);

    /**
     * @dev The owner withdraws the assets deposited at the time of the deposit period.
     *
     * @param assets The amount of assets to be withdrawn from the vault.
     * @param receiver The address that will receive the minted shares.
     * @param owner The address that owns the minted shares.
     * @param depositPeriod The related time period that the assets has deposited at, represents the ERC-1155 token ID.
     *
     * @return shares The amount of shares that the receiver can get.
     */
    function withdrawForDepositPeriod(uint256 assets, address receiver, address owner, uint256 depositPeriod)
        external
        returns (uint256 shares);

    /**
     * @dev This function allows the owner to withdraw assets from the vault regardless of the deposit periods.
     *
     * @param assets The amount of assets to be withdrawn from the vault.
     * @param receiver The address that will receive the minted shares.
     * @param owner The address that owns the minted shares.
     *
     * @return shares The amount of shares that the receiver can get.
     */
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

    // =============== Operational ===============

    /**
     * @dev Returns the current number of time periods elapsed.
     *
     * @return currentTimePeriodsElapsed The current number of time periods elapsed.
     */
    function currentTimePeriodsElapsed() external view returns (uint256);

    /**
     * @notice This function is for only testing purposes.
     * @dev This function is made to set the current number of time periods elapsed.
     *
     * @param currentTimePeriodsElapsed_ The current number of time periods elapsed.
     */
    function setCurrentTimePeriodsElapsed(uint256 currentTimePeriodsElapsed_) external;

    /**
     * @dev Get the total balance of assets currently deposited in the vault.
     *
     * @return balance The total amount of assets in the vault.
     */
    function totalBalance() external view returns (uint256 balance);
}
