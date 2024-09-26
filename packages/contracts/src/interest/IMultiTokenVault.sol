// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * @title IMultiTokenVault
 */
interface IMultiTokenVault is IERC1155 {
    /// @notice The event is being emitted once user deposits.
    event Deposit(
        address indexed sender, address indexed receiver, uint256 depositPeriod, uint256 assets, uint256 shares
    );

    /// @notice The event is being emitted once user withdraws.
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
     * @dev Returns the total amount of the underlying asset that is managed by vault.
     *
     * @return totalManagedAssets The total amount of the underlying asset that is managed by vault.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the shares held by the owner for deposit period.
     *
     * @param owner The owner address hold the shares.
     * @param depositPeriod The time period in which the user hold the shares.
     *
     * @return shares The total amount of ERC-1155 shares that is held by the owner.
     */
    function sharesAtPeriod(address owner, uint256 depositPeriod) external view returns (uint256 shares);

    // =============== Deposit ===============

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the vault for the receiver at the current period.
     *
     * @param receiver The user who wants to deposit.
     *
     * @return maxAssets The maximum amount of the underlying asset can be deposited.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Converts assets to shares for the deposit period.
     *
     * @param assets The amount of the ERC-20 underlying assets to be converted.
     * @param depositPeriod The time period in which the assets are converted.
     *
     * @return shares The amount of equivalent ERC-1155 shares.
     */
    function convertToSharesForDepositPeriod(uint256 assets, uint256 depositPeriod)
        external
        view
        returns (uint256 shares);

    /**
     * @dev Converts assets to shares at the current period.
     *
     * @param assets The amount of the ERC-20 underlying assets to be converted.
     *
     * @return shares The amount of equivalent ERC-1155 shares.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Simulate the deposit of the underlying assets into the vault and return the equivalent amount of shares for the current period.
     *
     * @param assets The amount of the ERC-20 underlying assets to be deposited.
     *
     * @return shares The amount of ERC-1155 tokens minted.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Deposits assets into the vault and mints shares for the current time period.
     *
     * @param assets The amount of the ERC-20 underlying assets to be deposited into the vault.
     * @param receiver The address that will receive the minted shares.
     *
     * @return shares The amount of ERC-1155 tokens minted.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    // =============== Redeem / Withdraw ===============

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner at the deposit period,
     * through a redeem call.
     *
     * @param owner The address of the owner that hold the assets.
     * @param depositPeriod The time period in which the redeem is called.
     *
     * @return maxShares The maximum amount of ERC-1155 tokens can be minted.
     */
    function maxRedeemAtPeriod(address owner, uint256 depositPeriod) external view returns (uint256 maxShares);

    /**
     * @dev Converts shares to assets for deposit period and redeem period.
     *
     * @param shares The amount of ERC-1155 tokens to be converted.
     * @param depositPeriod The time period in which the shares has been minted.
     * @param redeemPeriod The time period in which the shares are converted.
     *
     * @return assets The equivalent amount of the ERC-20 underlying asset.
     */
    function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod, uint256 redeemPeriod)
        external
        view
        returns (uint256 assets);

    /**
     * @dev Converts shares to assets for deposit period at the current redeem period.
     *
     * @param shares The amount of ERC-1155 tokens to be converted.
     * @param depositPeriod The time period in which the shares has been minted.
     *
     * @return assets The equivalent amount of the ERC-20 underlying asset.
     */
    function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod)
        external
        view
        returns (uint256 assets);

    /**
     * @dev Returns the amount of assets that will be redeemed for a given amount of shares at depositPeriod and redeemPeriod.
     *
     * @param shares The amount of ERC-1155 tokens to redeem.
     * @param depositPeriod The time period in which the shares has been minted.
     * @param redeemPeriod The time period in which the shares are redeemed.
     *
     * @return assets The equivalent amount of the ERC-20 underlying asset.
     */
    function previewRedeemForDepositPeriod(uint256 shares, uint256 depositPeriod, uint256 redeemPeriod)
        external
        view
        returns (uint256 assets);

    /**
     * @dev Returns the amount of assets that will be redeemed for a given amount of shares at a depositPeriod.
     *
     * @param shares The amount of the ERC-1155 tokens to redeem.
     * @param depositPeriod The deposit period in which the shares were issued.
     *
     * @return assets The equivalent amount of the ERC-20 underlying assets.
     */
    function previewRedeemForDepositPeriod(uint256 shares, uint256 depositPeriod)
        external
        view
        returns (uint256 assets);

    /**
     * @dev Redeems the shares minted at the time of the deposit period from the vault to the owner, while the redemption happens at the defined redeem period
     * And return the equivalent amount of assets to the receiver.
     *
     * @param shares The amount of the ERC-1155 tokens to redeem.
     * @param receiver The address that will receive the minted shares.
     * @param owner The address that owns the minted shares.
     * @param depositPeriod The deposit period in which the shares were issued.
     * @param redeemPeriod The time period in which the shares are redeemed.
     *
     * @return assets The equivalent amount of the ERC-20 underlying assets.
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
     * @param shares The amount of the ERC-1155 tokens to redeem.
     * @param receiver The address that will receive the minted shares.
     * @param owner The address that owns the minted shares.
     * @param depositPeriod The deposit period in which the shares were issued.
     *
     * @return assets The equivalent amount of the ERC-20 underlying assets.
     */
    function redeemForDepositPeriod(uint256 shares, address receiver, address owner, uint256 depositPeriod)
        external
        returns (uint256 assets);

    // =============== Operational ===============

    /**
     * @dev Returns the current number of time periods elapsed.
     *
     * @return _currentTimePeriodsElapsed The current number of time periods elapsed.
     */
    function currentTimePeriodsElapsed() external view returns (uint256 _currentTimePeriodsElapsed);

    /**
     * @notice This function is for only testing purposes.
     * @dev This function is made to set the current number of time periods elapsed.
     *
     * @param currentTimePeriodsElapsed_ The current number of time periods elapsed.
     */
    function setCurrentTimePeriodsElapsed(uint256 currentTimePeriodsElapsed_) external;
}
