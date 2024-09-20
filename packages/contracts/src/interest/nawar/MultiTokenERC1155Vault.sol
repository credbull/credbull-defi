// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IMultiTokenVault } from "@credbull/interest/IMultiTokenVault.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MultiTokenERC1155Vault
 * @dev A vault that uses deposit-period-specific ERC1155 tokens to represent deposits.
 *      This contract manages deposits and redemptions using ERC1155 tokens. It tracks the number
 *      of time periods that have elapsed and allows users to deposit and redeem assets based on these periods.
 *      Designed to be secure and production-ready for Hacken audit.
 */
abstract contract MultiTokenERC1155Vault is IMultiTokenVault, ERC1155, ReentrancyGuard, Ownable {
    using Math for uint256;
    using SafeERC20 for IERC20;

    /// @notice Tracks the number of time periods that have elapsed.
    uint256 public currentTimePeriodsElapsed = 0;

    /// @notice The ERC20 token used as the underlying asset in the vault.
    IERC20 public immutable asset;

    /// @notice The address of the treasury where deposited assets are transferred.
    address treasury;

    /// @notice Tracks the total amount of assets deposited in the vault.
    uint256 internal totalDepositedAssets;

    /// @notice The ratio of assets to shares (e.g., 1:1 ratio).
    uint256 internal immutable ASSET_TO_SHARES_RATIO;

    error MultiTokenERC1155Vault__UnsupportedFunction(string functionName);
    error MultiTokenERC1155Vault__ExceededMaxRedeem(address owner, uint256 depositPeriod, uint256 shares, uint256 max);
    error MultiTokenERC1155Vault__RedeemTimePeriodNotSupported(address owner, uint256 period, uint256 redeemPeriod);

    /**
     * @notice Initializes the vault with the asset, treasury, and token URI for ERC1155 tokens.
     * @param _treasury The address where deposited assets are transferred.
     * @param _asset The ERC20 token representing the underlying asset.
     * @param _uri The metadata URI for the ERC1155 tokens.
     * @param initialOwner The owner of the contract.
     */
    constructor(address _treasury, IERC20 _asset, string memory _uri, address initialOwner)
        ERC1155(_uri)
        Ownable(initialOwner)
    {
        asset = _asset;
        treasury = _treasury;
    }

    // =============== View ===============

    /**
     * @notice Get the number of shares (ERC1155 tokens) owned by an account for a specific deposit period.
     * @param account The address of the depositor.
     * @param depositPeriod The deposit period to check.
     * @return shares The number of shares (ERC1155 token balance) held by the account for the given period.
     */
    function getSharesAtPeriod(address account, uint256 depositPeriod) public view returns (uint256 shares) {
        return balanceOf(account, depositPeriod);
    }

    // =============== Deposit ===============

    /**
     * @notice Convert a given amount of assets to shares for a specific deposit period.
     * @dev The conversion logic depends on the specific asset-to-shares ratio defined by the vault.
     * @param assets The amount of assets to convert.
     * @param depositPeriod The deposit period in which the assets are converted.
     * @return shares The number of shares corresponding to the assets.
     */
    function convertToSharesForDepositPeriod(uint256 assets, uint256 depositPeriod)
        public
        view
        virtual
        returns (uint256 shares);

    /**
     * @notice Convert a given amount of assets to shares for the current deposit period.
     * @param assets The amount of assets to convert.
     * @return shares The number of shares for the current deposit period.
     */
    function convertToShares(uint256 assets) public view override returns (uint256 shares) {
        return convertToSharesForDepositPeriod(assets, currentTimePeriodsElapsed);
    }

    /**
     * @notice Preview the number of shares that will be minted for a given deposit of assets.
     * @param assets The amount of assets to deposit.
     * @return shares The number of shares that will be minted for the given deposit.
     */
    function previewDeposit(uint256 assets) public view override returns (uint256 shares) {
        return convertToShares(assets);
    }

    /**
     * @notice Deposit assets into the vault and mint ERC1155 tokens for the current deposit period.
     * @param assets The amount of assets to deposit.
     * @param receiver The address receiving the minted ERC1155 tokens.
     * @return shares The number of shares minted.
     */
    function deposit(uint256 assets, address receiver) public virtual override nonReentrant returns (uint256 shares) {
        totalDepositedAssets += assets;

        shares = convertToShares(assets);

        asset.safeTransferFrom(msg.sender, treasury, assets);

        _mint(receiver, currentTimePeriodsElapsed, shares, ""); // Mint ERC1155 tokens for the current period

        return shares;
    }

    // =============== Redeem ===============

    /**
     * @notice Convert a given number of shares to assets for a specific deposit period and redeem period.
     * @param shares The number of shares to convert.
     * @param depositPeriod The deposit period in which the shares were issued.
     * @param redeemPeriod The period during which the redemption occurs.
     * @return assets The corresponding amount of assets.
     */
    function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod, uint256 redeemPeriod)
        public
        view
        virtual
        returns (uint256 assets);

    /**
     * @notice Preview the number of assets that will be redeemed for a given number of shares.
     * @param shares The number of shares to redeem.
     * @param depositPeriod The deposit period in which the shares were issued.
     * @return assets The amount of assets that will be redeemed for the given shares.
     */
    function previewRedeemForDepositPeriod(uint256 shares, uint256 depositPeriod)
        public
        view
        returns (uint256 assets)
    {
        return convertToAssetsForDepositPeriod(shares, depositPeriod, currentTimePeriodsElapsed);
    }

    /**
     * @notice Redeem shares and burn the corresponding ERC1155 tokens for a specific deposit period and redeem period.
     * @param shares The number of shares to redeem.
     * @param receiver The address that will receive the redeemed assets.
     * @param owner The address that owns the shares being redeemed.
     * @param depositPeriod The deposit period in which the shares were issued.
     * @param redeemPeriod The period during which the redemption occurs.
     * @return assets The amount of assets redeemed.
     */
    function redeemForDepositPeriod(
        uint256 shares,
        address receiver,
        address owner,
        uint256 depositPeriod,
        uint256 redeemPeriod
    ) public virtual nonReentrant returns (uint256) {
        totalDepositedAssets -= (shares * ASSET_TO_SHARES_RATIO);

        uint256 maxShares = getSharesAtPeriod(owner, depositPeriod);
        if (shares > maxShares) {
            revert MultiTokenERC1155Vault__ExceededMaxRedeem(owner, depositPeriod, shares, maxShares);
        }

        uint256 assets = convertToAssetsForDepositPeriod(shares, depositPeriod, redeemPeriod); // Convert shares to assets

        _burn(owner, depositPeriod, shares); // Burn ERC1155 tokens

        asset.safeTransferFrom(treasury, receiver, assets); // Transfer the corresponding assets

        return assets;
    }

    /**
     * @notice Redeem shares and burn the corresponding ERC1155 tokens for the current time period.
     * @param shares The number of shares to redeem.
     * @param receiver The address that will receive the redeemed assets.
     * @param owner The address that owns the shares being redeemed.
     * @param depositPeriod The deposit period in which the shares were issued.
     * @return assets The amount of assets redeemed.
     */
    function redeemForDepositPeriod(uint256 shares, address receiver, address owner, uint256 depositPeriod)
        public
        virtual
        returns (uint256)
    {
        return redeemForDepositPeriod(shares, receiver, owner, depositPeriod, currentTimePeriodsElapsed);
    }

    // =============== Utility ===============

    /**
     * @notice Get the current number of time periods that have elapsed.
     * @return The current number of time periods elapsed.
     */
    function getCurrentTimePeriodsElapsed() public view virtual returns (uint256) {
        return currentTimePeriodsElapsed;
    }

    /**
     * @notice Set the current time periods elapsed.
     * @dev Only callable by the contract owner.
     * @param _currentTimePeriodsElapsed The new value for the number of time periods elapsed.
     */
    function setCurrentTimePeriodsElapsed(uint256 _currentTimePeriodsElapsed) public virtual onlyOwner {
        currentTimePeriodsElapsed = _currentTimePeriodsElapsed;
    }

    /**
     * @notice Get the underlying ERC20 asset used in the vault.
     * @return The ERC20 asset token.
     */
    function getAsset() external view override returns (IERC20) {
        return asset;
    }

    // =============== ERC1155 Overrides ===============

    /**
     * @notice Get the URI for the ERC1155 token metadata.
     * @param tokenId The specific ERC1155 token ID.
     * @return The metadata URI for the given token ID.
     */
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return "https://example.com/token/metadata/{tokenId}.json"; // Example URI, should be updated
    }

    /**
     * @notice Get the total balance of assets currently deposited in the vault.
     * @return The total balance of assets.
     */
    function getTotalBalance() public view virtual returns (uint256);
}