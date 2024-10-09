// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * @title IMultiTokenVault
 * @dev ERC4626 Vault-like interface for a vault that:
 *   - Users deposit ERC20 assets, and the vault returns ERC1155 share tokens specific to the deposit period.
 *   - Users redeem ERC1155 share tokens, and the vault returns the corresponding amount of ERC20 assets.
 *   - Each deposit period has its own ERC1155 share token, allowing for time-based calculations, e.g. for returns.
 */
interface IMultiTokenVault is IERC1155 {
    /// @notice The event is being emitted once user deposits.
    event Deposit(
        address indexed sender, address indexed receiver, uint256 depositPeriod, uint256 assets, uint256 shares
    );

    /// @notice Emitted when a user withdraws assets from the vault.
    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 depositPeriod,
        uint256 assets,
        uint256 shares
    );

    /**
     * @notice Deposits assets into the vault for the current deposit period.
     * @param assets The amount of assets to be deposited.
     * @param receiver The address to receive the shares.
     * @return shares The amount of shares returned.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @notice Redeems shares for assets based on a specific deposit period.
     * @param shares The amount of shares to redeem.
     * @param receiver The address to receive the assets.
     * @param owner The address of the owner of the shares.
     * @param depositPeriod The deposit period in which the shares were issued.
     * @return assets The equivalent amount of assets returned.
     */
    function redeemForDepositPeriod(uint256 shares, address receiver, address owner, uint256 depositPeriod)
        external
        returns (uint256 assets);

    /**
     * @notice Redeems shares for assets based on a specific deposit and redeem period.
     * @param shares The amount of shares to redeem.
     * @param receiver The address to receive the assets.
     * @param owner The address of the owner of the shares.
     * @param depositPeriod The deposit period in which the shares were issued.
     * @param redeemPeriod The period in which the shares are redeemed.
     * @return assets The equivalent amount of assets returned.
     */
    function redeemForDepositPeriod(
        uint256 shares,
        address receiver,
        address owner,
        uint256 depositPeriod,
        uint256 redeemPeriod
    ) external returns (uint256 assets);

    /**
     * @notice Returns the underlying asset used by the vault.
     * @return asset_ The address of the underlying asset.
     */
    function asset() external view returns (address asset_);

    /**
     * @notice Returns the shares held by the owner for a specific deposit period.
     * @param owner The address holding the shares.
     * @param depositPeriod The deposit period in which the shares were issued.
     * @return shares The amount of shares held by the owner.
     */
    function sharesAtPeriod(address owner, uint256 depositPeriod) external view returns (uint256 shares);

    /**
     * @notice Returns the maximum amount of assets that can be deposited for the receiver.
     * @param receiver The address to receive the shares.
     * @return maxAssets The maximum amount of assets that can be deposited.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @notice Converts a given amount of assets to shares for a specific deposit period.
     * @param assets The amount of assets to convert.
     * @param depositPeriod The period during which the shares are minted.
     * @return shares The equivalent amount of shares.
     */
    function convertToSharesForDepositPeriod(uint256 assets, uint256 depositPeriod)
        external
        view
        returns (uint256 shares);

    /**
     * @notice Converts a given amount of assets to shares at the current period.
     * @param assets The amount of assets to convert.
     * @return shares The equivalent amount of shares.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @notice Simulates the deposit of assets and returns the equivalent shares.
     * @param assets The amount of assets to simulate depositing.
     * @return shares The equivalent amount of shares.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @notice Returns the maximum shares that can be redeemed for a specific deposit period.
     * @param owner The address holding the shares.
     * @param depositPeriod The deposit period in which the shares were issued.
     * @return maxShares The maximum amount of shares that can be redeemed.
     */
    function maxRedeemAtPeriod(address owner, uint256 depositPeriod) external view returns (uint256 maxShares);

    /**
     * @notice Converts shares to assets for a specific deposit period at the current redeem period.
     * @param shares The amount of shares to convert.
     * @param depositPeriod The period during which the shares were issued.
     * @return assets The equivalent amount of assets.
     */
    function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod)
        external
        view
        returns (uint256 assets);

    /**
     * @notice Converts shares to assets for a specific deposit and redeem period.
     * @param shares The amount of shares to convert.
     * @param depositPeriod The period during which the shares were issued.
     * @param redeemPeriod The period during which the shares are redeemed.
     * @return assets The equivalent amount of assets.
     */
    function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod, uint256 redeemPeriod)
        external
        view
        returns (uint256 assets);

    /**
     * @notice Converts shares to assets for the deposit periods at the redeem period.
     * @param shares The amount of shares to convert.
     * @param depositPeriods The periods during which the shares were issued.
     * @param redeemPeriod The period during which the shares are redeemed.
     * @return assets The equivalent amount of assets.
     */
    function convertToAssetsForDepositPeriodBatch(
        uint256[] memory shares,
        uint256[] memory depositPeriods,
        uint256 redeemPeriod
    ) external view returns (uint256[] memory assets);

    /**
     * @notice Simulates the redemption of shares and returns the equivalent assets.
     * @param shares The amount of shares to redeem.
     * @param depositPeriod The deposit period in which the shares were issued.
     * @param redeemPeriod The period in which the shares are redeemed.
     * @return assets The estimated amount of assets returned.
     */
    function previewRedeemForDepositPeriod(uint256 shares, uint256 depositPeriod, uint256 redeemPeriod)
        external
        view
        returns (uint256 assets);

    /**
     * @notice Simulates the redemption of shares for a specific deposit period.
     * @param shares The amount of shares to redeem.
     * @param depositPeriod The deposit period in which the shares were issued.
     * @return assets The estimated amount of assets returned.
     */
    function previewRedeemForDepositPeriod(uint256 shares, uint256 depositPeriod)
        external
        view
        returns (uint256 assets);

    /**
     * @notice Returns the current number of elapsed time periods since the vault started.
     * @return currentPeriodsElapsed_ The number of elapsed time periods.
     */
    function currentPeriodsElapsed() external view returns (uint256 currentPeriodsElapsed_);

    /**
     * @notice Indicates whether any token exist with a given `depositPeriod`, or not.
     * @return [true] if there is supply at `depositPeriod`, [false] otherwise.
     */
    function exists(uint256 depositPeriod) external view returns (bool);
}
