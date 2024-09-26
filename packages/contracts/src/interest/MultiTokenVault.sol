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
 * @title MultiTokenVault
 * @dev A vault that uses deposit-period-specific ERC1155 tokens to represent deposits.
 *      This contract manages deposits and redemptions using ERC1155 tokens. It tracks the number
 *      of time periods that have elapsed and allows users to deposit and redeem assets based on these periods.
 *      Designed to be secure and production-ready for Hacken audit.
 */
abstract contract MultiTokenVault is IMultiTokenVault, ERC1155, ReentrancyGuard, Ownable {
    using Math for uint256;
    using SafeERC20 for IERC20;

    /// @notice Tracks the number of time periods that have elapsed.
    uint256 private _currentTimePeriodsElapsed;

    /// @notice The ERC20 token used as the underlying asset in the vault.
    IERC20 private immutable _asset;

    /// @notice Tracks the total amount of assets deposited in the vault.
    uint256 internal totalDepositedAssets;

    error MultiTokenVault__ExceededMaxRedeem(address owner, uint256 depositPeriod, uint256 shares, uint256 maxShares);
    error MultiTokenVault__ExceededMaxDeposit(
        address receiver, uint256 depositPeriod, uint256 assets, uint256 maxAssets
    );

    error MultiTokenVault__RedeemTimePeriodNotSupported(address owner, uint256 period, uint256 redeemPeriod);
    error MultiTokenVault__CallerMissingApprovalForAll(address operator, address owner);
    error MultiTokenVault__RedeemBeforeDeposit(address owner, uint256 depositPeriod, uint256 redeemPeriod);
    /**
     * @notice Initializes the vault with the asset, treasury, and token URI for ERC1155 tokens.
     * @param asset_ The ERC20 token representing the underlying asset.
     * @param initialOwner The owner of the contract.
     */

    constructor(IERC20 asset_, address initialOwner) ERC1155("") Ownable(initialOwner) {
        _asset = asset_;
    }

    // =============== View ===============

    /**
     * @notice Get the number of shares (ERC1155 tokens) owned by an account for a specific deposit period.
     * @param account The address of the depositor.
     * @param depositPeriod The deposit period to check.
     * @return shares The number of shares (ERC1155 token balance) held by the account for the given period.
     */
    function sharesAtPeriod(address account, uint256 depositPeriod) public view returns (uint256 shares) {
        return balanceOf(account, depositPeriod);
    }

    // =============== Deposit ===============

    function maxDeposit(address /*receiver*/ ) public view virtual returns (uint256) {
        return type(uint256).max;
    }

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
    function convertToShares(uint256 assets) public view virtual returns (uint256 shares) {
        return convertToSharesForDepositPeriod(assets, currentTimePeriodsElapsed());
    }

    function previewDeposit(uint256 assets) public view override returns (uint256 shares) {
        shares = convertToShares(assets);
    }

    /**
     * @dev Deposits assets into the vault and mints shares for the current time period.
     * Initially, assets and shares are equivalent.
     * @param assets The amount of asset to be deposited into the vault.
     * @param receiver The address that will receive the minted shares.
     * @return shares The amount of ERC1155 tokens minted, where the `depositPeriod` acts as the token ID.
     */
    function deposit(uint256 assets, address receiver) public virtual override nonReentrant returns (uint256 shares) {
        uint256 maxAssets = maxDeposit(receiver);
        uint256 depositPeriod = currentTimePeriodsElapsed();

        if (assets > maxAssets) {
            revert MultiTokenVault__ExceededMaxDeposit(receiver, depositPeriod, assets, maxAssets);
        }

        shares = previewDeposit(assets);

        _deposit(_msgSender(), receiver, depositPeriod, assets, shares);
    }

    function _deposit(address caller, address receiver, uint256 depositPeriod, uint256 assets, uint256 shares)
        internal
        virtual
    {
        totalDepositedAssets += assets;

        _asset.safeTransferFrom(caller, address(this), assets);
        _mint(receiver, depositPeriod, shares, "");
        emit Deposit(msg.sender, receiver, depositPeriod, assets, shares);
    }

    // =============== Redeem ===============
    function maxRedeemAtPeriod(address owner, uint256 depositPeriod) public view virtual returns (uint256) {
        return balanceOf(owner, depositPeriod);
    }

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

    function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod)
        public
        view
        virtual
        returns (uint256)
    {
        return convertToAssetsForDepositPeriod(shares, depositPeriod, currentTimePeriodsElapsed());
    }

    function previewRedeemForDepositPeriod(uint256 shares, uint256 depositPeriod, uint256 redeemPeriod)
        public
        view
        virtual
        returns (uint256 assets)
    {
        return convertToAssetsForDepositPeriod(shares, depositPeriod, redeemPeriod);
    }

    /**
     * @notice Preview the number of assets that will be redeemed for a given number of shares.
     * @param shares The number of shares to redeem.
     * @param depositPeriod The deposit period in which the shares were issued.
     * @return assets The amount of assets that will be redeemed for the given shares.
     */
    function previewRedeemForDepositPeriod(uint256 shares, uint256 depositPeriod)
        public
        view
        virtual
        returns (uint256 assets)
    {
        return previewRedeemForDepositPeriod(shares, depositPeriod, currentTimePeriodsElapsed());
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
    ) public virtual nonReentrant returns (uint256 assets) {
        if (depositPeriod > redeemPeriod) {
            revert MultiTokenVault__RedeemBeforeDeposit(owner, depositPeriod, redeemPeriod);
        }

        if (currentTimePeriodsElapsed() < redeemPeriod) {
            revert MultiTokenVault__RedeemTimePeriodNotSupported(owner, currentTimePeriodsElapsed(), redeemPeriod);
        }

        uint256 maxShares = maxRedeemAtPeriod(owner, depositPeriod);

        if (shares > maxShares) {
            revert MultiTokenVault__ExceededMaxRedeem(owner, depositPeriod, shares, maxShares);
        }

        assets = previewRedeemForDepositPeriod(shares, depositPeriod, redeemPeriod);

        _withdraw(msg.sender, receiver, owner, depositPeriod, assets, shares);
    }

    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 depositPeriod,
        uint256 assets,
        uint256 shares
    ) internal virtual {
        if (caller != owner && isApprovedForAll(owner, caller)) {
            revert MultiTokenVault__CallerMissingApprovalForAll(caller, owner);
        }

        totalDepositedAssets -= assets;

        _burn(owner, depositPeriod, shares);

        _asset.safeTransfer(receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, depositPeriod, assets, shares);
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
        return redeemForDepositPeriod(shares, receiver, owner, depositPeriod, currentTimePeriodsElapsed());
    }

    // =============== Utility ===============
    function asset() public view virtual returns (address) {
        return address(_asset);
    }

    function currentTimePeriodsElapsed() public view virtual returns (uint256) {
        return _currentTimePeriodsElapsed;
    }

    /**
     * @notice Set the current time periods elapsed.
     * @dev Only callable by the contract owner.
     * @param currentTimePeriodsElapsed_ The new value for the number of time periods elapsed.
     */
    function setCurrentTimePeriodsElapsed(uint256 currentTimePeriodsElapsed_) public virtual onlyOwner {
        _currentTimePeriodsElapsed = currentTimePeriodsElapsed_;
    }

    /**
     * @notice Get the total balance of assets currently deposited in the vault.
     * @return The total balance of assets.
     */
    function getTotalBalance() public view virtual returns (uint256);
}
