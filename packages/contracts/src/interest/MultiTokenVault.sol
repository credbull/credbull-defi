// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IMultiTokenVault } from "@credbull/interest/IMultiTokenVault.sol";
import { ERC1155Supply, ERC1155 } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IERC1155Receiver } from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

/**
 * @title MultiTokenVault
 * @dev A vault that uses deposit-period-specific ERC1155 tokens to represent deposits.
 *      This contract manages deposits and redemptions using ERC1155 tokens. It tracks the number
 *      of time periods that have elapsed and allows users to deposit and redeem assets based on these periods.
 *      Designed to be secure and production-ready for Hacken audit.
 */
abstract contract MultiTokenVault is ERC1155Supply, IMultiTokenVault, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    /// @notice Tracks the number of time periods that have elapsed.
    uint256 internal _currentTimePeriodsElapsed;

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
     * @param initialOwner The owner of the contract.
     */
    constructor(IERC20 asset_, address initialOwner) ERC1155("") Ownable(initialOwner) {
        ASSET = asset_;
    }

    /**
     * @dev Returns the total amount of the underlying asset that is managed by vault.
     *
     * @return totalManagedAssets The total amount of the underlying asset that is managed by vault.
     */
    function totalAssets() external view returns (uint256) {
        return totalSupply();
    }

    /**
     * @dev Deposits assets into the vault and mints shares for the current time period.
     *
     * @param assets The amount of the ERC-20 underlying assets to be deposited into the vault.
     * @param receiver The address that will receive the minted shares.
     *
     * @return shares The amount of ERC-1155 tokens minted.
     */
    function deposit(uint256 assets, address receiver) public virtual override nonReentrant returns (uint256 shares) {
        uint256 maxAssets = maxDeposit(receiver);
        uint256 depositPeriod = currentTimePeriodsElapsed();

        if (assets > maxAssets) {
            revert MultiTokenVault__ExceededMaxDeposit(receiver, depositPeriod, assets, maxAssets);
        }

        // Check if the receiver is a contract and supports IERC1155Receiver
        if (receiver.code.length > 0) {
            require(
                IERC165(receiver).supportsInterface(type(IERC1155Receiver).interfaceId),
                "MultiTokenVault: Receiver does not implement IERC1155Receiver"
            );
        }

        shares = previewDeposit(assets);

        _deposit(assets, receiver, _msgSender(), depositPeriod, shares);
    }

    /**
     * @dev Redeems the shares minted at the time of the deposit period from the vault to the owner,
     *      while the redemption happens at the defined redeem period
     *      And return the equivalent amount of assets to the receiver.
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

        _withdraw(shares, receiver, owner, _msgSender(), depositPeriod, assets);
    }

    /**
     * @dev Redeems the shares minted at the time of the deposit period from the vault to the owner,
     *      while the redemption happens at the current redeem period
     *      And return the equivalent amount of assets to the receiver.
     *
     * @param shares The amount of the ERC-1155 tokens to redeem.
     * @param receiver The address that will receive the minted shares.
     * @param owner The address that owns the minted shares.
     * @param depositPeriod The deposit period in which the shares were issued.
     *
     * @return assets The equivalent amount of the ERC-20 underlying assets.
     */
    function redeemForDepositPeriod(uint256 shares, address receiver, address owner, uint256 depositPeriod)
        public
        virtual
        returns (uint256)
    {
        return redeemForDepositPeriod(shares, receiver, owner, depositPeriod, currentTimePeriodsElapsed());
    }

    /**
     * @notice This function is for only testing purposes.
     * @dev This function is made to set the current number of time periods elapsed.
     *
     * @param currentTimePeriodsElapsed_ The current number of time periods elapsed.
     */
    function setCurrentTimePeriodsElapsed(uint256 currentTimePeriodsElapsed_) public virtual onlyOwner {
        _currentTimePeriodsElapsed = currentTimePeriodsElapsed_;
    }

    /**
     * @dev Returns the ERC-20 underlying asset address used in the vault.
     *
     * @return asset The ERC-20 underlying asset address.
     */
    function asset() public view virtual returns (address) {
        return address(ASSET);
    }

    /**
     * @dev Returns the shares held by the owner for deposit period.
     *
     * @param owner The owner address hold the shares.
     * @param depositPeriod The time period in which the user hold the shares.
     *
     * @return shares The total amount of ERC-1155 shares that is held by the owner.
     */
    function sharesAtPeriod(address owner, uint256 depositPeriod) public view returns (uint256 shares) {
        return balanceOf(owner, depositPeriod);
    }

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into
     *      the vault for the receiver at the current period.
     */
    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    /**
     * @dev Converts assets to shares for the deposit period.
     *
     * @param assets The amount of the ERC-20 underlying assets to be converted.
     * @param depositPeriod The time period in which the assets are converted.
     *
     * @return shares The amount of equivalent ERC-1155 shares.
     */
    function convertToSharesForDepositPeriod(uint256 assets, uint256 depositPeriod)
        public
        view
        virtual
        returns (uint256 shares);

    /**
     * @dev Converts assets to shares at the current period.
     *
     * @param assets The amount of the ERC-20 underlying assets to be converted.
     *
     * @return shares The amount of equivalent ERC-1155 shares.
     */
    function convertToShares(uint256 assets) public view virtual returns (uint256 shares) {
        return convertToSharesForDepositPeriod(assets, currentTimePeriodsElapsed());
    }

    /**
     * @dev Simulate the deposit of the underlying assets into the vault and return
     *      the equivalent amount of shares for the current period.
     *
     * @param assets The amount of the ERC-20 underlying assets to be deposited.
     *
     * @return shares The amount of ERC-1155 tokens minted.
     */
    function previewDeposit(uint256 assets) public view override returns (uint256 shares) {
        shares = convertToShares(assets);
    }

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from
     *      the owner at the deposit period, through a redeem call.
     *
     * @param owner The address of the owner that hold the assets.
     * @param depositPeriod The time period in which the redeem is called.
     *
     * @return maxShares The maximum amount of ERC-1155 tokens can be minted.
     */
    function maxRedeemAtPeriod(address owner, uint256 depositPeriod) public view virtual returns (uint256 maxShares) {
        return balanceOf(owner, depositPeriod);
    }

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
        public
        view
        virtual
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
        public
        view
        virtual
        returns (uint256)
    {
        return convertToAssetsForDepositPeriod(shares, depositPeriod, currentTimePeriodsElapsed());
    }

    /**
     * @dev Returns the amount of assets that will be redeemed for a given amount of
     *      shares at depositPeriod and redeemPeriod.
     *
     * @param shares The amount of ERC-1155 tokens to redeem.
     * @param depositPeriod The time period in which the shares has been minted.
     * @param redeemPeriod The time period in which the shares are redeemed.
     *
     * @return assets The equivalent amount of the ERC-20 underlying asset.
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
     * @dev Returns the amount of assets that will be redeemed for a given amount of shares at a depositPeriod.
     *
     * @param shares The amount of the ERC-1155 tokens to redeem.
     * @param depositPeriod The deposit period in which the shares were issued.
     *
     * @return assets The equivalent amount of the ERC-20 underlying assets.
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
     * @dev Returns the current number of time periods elapsed.
     *
     * @return _currentTimePeriodsElapsed The current number of time periods elapsed.
     */
    function currentTimePeriodsElapsed() public view virtual returns (uint256) {
        return _currentTimePeriodsElapsed;
    }

    /**
     * @dev Returns true if this contract implements the interface defined by `interfaceId`.
     *      This function checks for support of the IERC1155 interface, IMultiTokenVault interface,
     *      and delegates to the super class for any other interface support checks.
     *
     * @param interfaceId The identifier of the interface to check for support.
     * @return bool True if the contract supports the requested interface.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC1155) returns (bool) {
        return interfaceId == type(IMultiTokenVault).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev An internal function to implement the functionality of depositing assets into the vault
     *      and mints shares for the current time period.
     *
     * @param assets The amount of the ERC-20 underlying assets to be deposited into the vault.
     * @param receiver The address that will receive the minted shares.
     * @param caller The address of who is depositing the assets.
     * @param depositPeriod The time period in which the assets are deposited.
     * @param shares The amount of ERC-1155 tokens minted.
     */
    function _deposit(uint256 assets, address receiver, address caller, uint256 depositPeriod, uint256 shares)
        internal
        virtual
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
     * @param shares The amount of the ERC-1155 tokens to redeem.
     * @param receiver The address that will receive the minted shares.
     * @param owner The address that owns the minted shares.
     * @param caller The address of who is redeeming the shares.
     * @param depositPeriod The deposit period in which the shares were minted.
     * @param assets The equivalent amount of the ERC-20 underlying assets.
     */
    function _withdraw(
        uint256 shares,
        address receiver,
        address owner,
        address caller,
        uint256 depositPeriod,
        uint256 assets
    ) internal virtual {
        if (caller != owner && isApprovedForAll(owner, caller)) {
            revert MultiTokenVault__CallerMissingApprovalForAll(caller, owner);
        }

        _burn(owner, depositPeriod, shares);

        ASSET.safeTransfer(receiver, assets);

        emit Withdraw(caller, receiver, owner, depositPeriod, assets, shares);
    }
}
