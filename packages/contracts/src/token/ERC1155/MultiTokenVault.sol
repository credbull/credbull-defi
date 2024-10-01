// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IMultiTokenVault } from "@credbull/token/ERC1155/IMultiTokenVault.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title MultiTokenVault
 * @dev A vault that uses deposit-period-specific ERC1155 tokens to represent deposits.
 *      This contract manages deposits and redemptions using ERC1155 tokens. It tracks the number
 *      of time periods that have elapsed and allows users to deposit and redeem assets based on these periods.
 *      Designed to be secure and production-ready for Hacken audit.
 */
abstract contract MultiTokenVault is ERC1155, IMultiTokenVault, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice The ERC20 token used as the underlying asset in the vault.
    IERC20 private immutable ASSET;

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
     */
    constructor(IERC20 asset_) ERC1155("") {
        ASSET = asset_;
    }

    /**
     * @inheritdoc IMultiTokenVault
     */
    function deposit(uint256 assets, address receiver) public virtual override returns (uint256 shares) {
        return _depositForDepositPeriod(assets, receiver, currentPeriodsElapsed());
    }

    function _depositForDepositPeriod(uint256 assets, address receiver, uint256 depositPeriod)
        internal
        virtual
        returns (uint256 shares)
    {
        uint256 maxAssets = maxDeposit(receiver);

        if (assets > maxAssets) {
            revert MultiTokenVault__ExceededMaxDeposit(receiver, depositPeriod, assets, maxAssets);
        }

        shares = previewDeposit(assets);

        _deposit(_msgSender(), receiver, depositPeriod, assets, shares);
    }

    /**
     * @inheritdoc IMultiTokenVault
     */
    function redeemForDepositPeriod(
        uint256 shares,
        address receiver,
        address owner,
        uint256 depositPeriod,
        uint256 redeemPeriod
    ) public virtual returns (uint256 assets) {
        if (depositPeriod > redeemPeriod) {
            revert MultiTokenVault__RedeemBeforeDeposit(owner, depositPeriod, redeemPeriod);
        }

        if (currentPeriodsElapsed() < redeemPeriod) {
            revert MultiTokenVault__RedeemTimePeriodNotSupported(owner, currentPeriodsElapsed(), redeemPeriod);
        }

        uint256 maxShares = maxRedeemAtPeriod(owner, depositPeriod);

        if (shares > maxShares) {
            revert MultiTokenVault__ExceededMaxRedeem(owner, depositPeriod, shares, maxShares);
        }

        assets = previewRedeemForDepositPeriod(shares, depositPeriod, redeemPeriod);

        _withdraw(_msgSender(), receiver, owner, depositPeriod, assets, shares);
    }

    /**
     * @inheritdoc IMultiTokenVault
     */
    function redeemForDepositPeriod(uint256 shares, address receiver, address owner, uint256 depositPeriod)
        public
        virtual
        returns (uint256)
    {
        return redeemForDepositPeriod(shares, receiver, owner, depositPeriod, currentPeriodsElapsed());
    }

    /**
     * @inheritdoc IMultiTokenVault
     */
    function asset() public view virtual returns (address asset_) {
        return address(ASSET);
    }

    function assetIERC20() public view virtual returns (IERC20 assetIERC20_) {
        return ASSET;
    }

    /**
     * @inheritdoc IMultiTokenVault
     */
    function sharesAtPeriod(address owner, uint256 depositPeriod) public view returns (uint256 shares) {
        return balanceOf(owner, depositPeriod);
    }

    /**
     * @inheritdoc IMultiTokenVault
     */
    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    /**
     * @inheritdoc IMultiTokenVault
     */
    function convertToSharesForDepositPeriod(uint256 assets, uint256 depositPeriod)
        public
        view
        virtual
        returns (uint256 shares);

    /**
     * @inheritdoc IMultiTokenVault
     */
    function convertToShares(uint256 assets) public view virtual returns (uint256 shares) {
        return convertToSharesForDepositPeriod(assets, currentPeriodsElapsed());
    }

    /**
     * @inheritdoc IMultiTokenVault
     */
    function previewDeposit(uint256 assets) public view override returns (uint256 shares) {
        shares = convertToShares(assets);
    }

    /**
     * @inheritdoc IMultiTokenVault
     */
    function maxRedeemAtPeriod(address owner, uint256 depositPeriod) public view virtual returns (uint256 maxShares) {
        return balanceOf(owner, depositPeriod);
    }

    /**
     * @inheritdoc IMultiTokenVault
     */
    function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod, uint256 redeemPeriod)
        public
        view
        virtual
        returns (uint256 assets);

    /**
     * @inheritdoc IMultiTokenVault
     */
    function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod)
        public
        view
        virtual
        returns (uint256)
    {
        return convertToAssetsForDepositPeriod(shares, depositPeriod, currentPeriodsElapsed());
    }

    /**
     * @inheritdoc IMultiTokenVault
     */
    function previewRedeemForDepositPeriod(uint256 shares, uint256 depositPeriod, uint256 redeemPeriod)
        public
        view
        virtual
        returns (uint256 assets)
    {
        return convertToAssetsForDepositPeriod(shares, depositPeriod, redeemPeriod);
    }

    /**
     * @inheritdoc IMultiTokenVault
     */
    function previewRedeemForDepositPeriod(uint256 shares, uint256 depositPeriod)
        public
        view
        virtual
        returns (uint256 assets)
    {
        return previewRedeemForDepositPeriod(shares, depositPeriod, currentPeriodsElapsed());
    }

    /**
     * @inheritdoc IMultiTokenVault
     */
    function currentPeriodsElapsed() public view virtual returns (uint256 currentPeriod_);

    /**
     * @dev Returns true if this contract implements the interface defined by `interfaceId`.
     *      This function checks for support of the IERC1155 interface, IMultiTokenVault interface,
     *      and delegates to the super class for any other interface support checks.
     *
     * @param interfaceId The identifier of the interface to check for support.
     *
     * @return bool True if the contract supports the requested interface.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC1155) returns (bool) {
        return interfaceId == type(IMultiTokenVault).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev An internal function to implement the functionality of depositing assets into the vault
     *      and mints shares for the current time period.
     *
     * @param caller The address of who is depositing the assets.
     * @param receiver The address that will receive the minted shares.
     * @param depositPeriod The time period in which the assets are deposited.
     * @param assets The amount of the ERC-20 underlying assets to be deposited into the vault.
     * @param shares The amount of ERC-1155 tokens minted.
     */
    function _deposit(address caller, address receiver, uint256 depositPeriod, uint256 assets, uint256 shares)
        internal
        virtual
        nonReentrant
    {
        ASSET.safeTransferFrom(caller, address(this), assets);
        _mint(receiver, depositPeriod, shares, "");
        emit Deposit(caller, receiver, depositPeriod, assets, shares);
    }

    /**
     * @dev Redeems the shares minted at the time of the deposit period from the vault to the owner,
     *      while the redemption happens at the defined redeem period
     *      And return the equivalent amount of assets to the receiver.
     *
     * @param caller The address of who is redeeming the shares.
     * @param receiver The address that will receive the minted shares.
     * @param owner The address that owns the minted shares.
     * @param depositPeriod The deposit period in which the shares were minted.
     * @param assets The equivalent amount of the ERC-20 underlying assets.
     * @param shares The amount of the ERC-1155 tokens to redeem.
     */
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 depositPeriod,
        uint256 assets,
        uint256 shares
    ) internal virtual nonReentrant {
        if (caller != owner && isApprovedForAll(owner, caller)) {
            revert MultiTokenVault__CallerMissingApprovalForAll(caller, owner);
        }

        _burn(owner, depositPeriod, shares);

        ASSET.safeTransfer(receiver, assets);

        emit Withdraw(caller, receiver, owner, depositPeriod, assets, shares);
    }
}