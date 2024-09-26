// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IMultiTokenVault } from "@credbull/interest/IMultiTokenVault.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title MultiTokenVault
 * @dev A vault that uses SimpleInterest and Discounting to calculate shares per asset.
 *      The vault manages deposits and redemptions based on elapsed time periods and applies simple interest calculations.
 */
abstract contract MultiTokenVault is IMultiTokenVault, ERC1155 {
    using Math for uint256;
    using SafeERC20 for IERC20;

    // TODO lucas - temp (start)
    error IMultiTokenVault__RedeemBeforeDeposit(address owner, uint256 depositPeriod, uint256 redeemPeriod);
    error IMultiTokenVault__RedeemPeriodNotSupported(address owner, uint256 currentPeriod, uint256 redeemPeriod);
    // TODO lucas - temp (end)

    uint256 public currentPeriodElapsed = 0; // the current number of time periods elapsed

    /// @notice The ERC20 token used as the underlying asset in the vault.
    IERC20 private immutable ASSET;

    error MultiTokenVault__UnsupportedFunction(string functionName);
    error MultiTokenVault__ExceededMaxRedeem(address owner, uint256 depositPeriod, uint256 shares, uint256 max);

    constructor(IERC20Metadata asset_) ERC1155("") {
        ASSET = asset_;
    }

    // =============== View ===============

    /**
     * @dev See {IMultiTokenVault-getSharesAtPeriod}
     */
    function sharesAtPeriod(address account, uint256 depositPeriod) public view returns (uint256 shares) {
        return balanceOf(account, depositPeriod);
    }

    // =============== Deposit ===============

    /**
     * @dev See {IMultiTokenVault-convertToSharesForDepositPeriod}
     */
    function convertToSharesForDepositPeriod(uint256 assets, uint256 depositPeriod)
        public
        view
        virtual
        returns (uint256 shares);

    /**
     * @dev See {IMultiTokenVault-convertToShares}
     */
    function convertToShares(uint256 assets) public view override returns (uint256 shares) {
        return convertToSharesForDepositPeriod(assets, currentPeriodElapsed);
    }

    /**
     * @dev See {IMultiTokenVault-previewDeposit}
     */
    function previewDeposit(uint256 assets) public view override returns (uint256 shares) {
        return convertToShares(assets);
    }

    /**
     * @dev See {IMultiTokenVault-deposit}
     */
    function deposit(uint256 assets, address receiver) public virtual override returns (uint256) {
        uint256 shares = previewDeposit(assets);

        ASSET.safeTransferFrom(_msgSender(), address(this), assets);

        _mint(receiver, currentPeriodElapsed, shares, "");

        return shares;
    }

    // =============== Redeem ===============

    /**
     * @dev See {IMultiTokenVault-convertToAssetsForDepositPeriod}
     */
    function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod, uint256 redeemPeriod)
        public
        view
        virtual
        returns (uint256 assets);

    /**
     * @dev See {IMultiTokenVault-previewRedeemForDepositPeriod}
     */
    function previewRedeemForDepositPeriod(uint256 shares, uint256 depositPeriod, uint256 redeemPeriod)
        public
        view
        returns (uint256 assets)
    {
        return convertToAssetsForDepositPeriod(shares, depositPeriod, redeemPeriod);
    }

    /**
     * @dev See {IMultiTokenVault-redeemForDepositPeriod}
     */
    function redeemForDepositPeriod(
        uint256 shares,
        address receiver,
        address owner,
        uint256 depositPeriod,
        uint256 redeemPeriod
    ) public virtual returns (uint256 assets_) {
        if (depositPeriod > redeemPeriod) {
            revert IMultiTokenVault__RedeemBeforeDeposit(owner, depositPeriod, redeemPeriod);
        }

        // TODO confirm rules around which day (or days) we allow redeems
        if (currentPeriodElapsed != redeemPeriod) {
            revert IMultiTokenVault__RedeemPeriodNotSupported(owner, currentPeriodElapsed, redeemPeriod);
        }

        uint256 maxShares = sharesAtPeriod(owner, depositPeriod);
        if (shares > maxShares) {
            revert MultiTokenVault__ExceededMaxRedeem(owner, depositPeriod, shares, maxShares);
        }

        _burn(owner, depositPeriod, shares); // deposit specific

        // logic for fungible shares below
        uint256 assets = previewRedeemForDepositPeriod(shares, depositPeriod);

        ASSET.safeTransfer(receiver, assets);

        return assets;
    }

    /**
     * @dev See {IMultiTokenVault-convertToAssetsForDepositPeriod}
     */
    function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod)
        public
        view
        returns (uint256 assets)
    {
        return convertToAssetsForDepositPeriod(shares, depositPeriod, currentPeriodElapsed);
    }

    /**
     * @dev See {IMultiTokenVault-previewRedeemForDepositPeriod}
     */
    function previewRedeemForDepositPeriod(uint256 shares, uint256 depositPeriod)
        public
        view
        returns (uint256 assets)
    {
        return previewRedeemForDepositPeriod(shares, depositPeriod, currentPeriodElapsed);
    }

    /**
     * @dev See {IMultiTokenVault-redeemForDepositPeriod}
     */
    function redeemForDepositPeriod(uint256 shares, address receiver, address owner, uint256 depositPeriod)
        public
        returns (uint256 assets)
    {
        return redeemForDepositPeriod(shares, receiver, owner, depositPeriod, currentPeriodElapsed);
    }

    // =============== ERC4626 and ERC20 ===============

    /**
     * @dev See {IMultiTokenVault-asset}
     */
    function asset() public view virtual override returns (address asset_) {
        return address(ASSET);
    }

    /**
     * @dev See {ERC20-decimals}
     */
    function decimals() public view virtual returns (uint8) {
        return IERC20Metadata(address(ASSET)).decimals();
    }

    // =============== Utility ===============

    /**
     * @dev See {IMultiTokenVault-getCurrentTimePeriodsElapsed}
     */
    function currentTimePeriodsElapsed() public view virtual returns (uint256 currentTimePeriodsElapsed_) {
        return currentPeriodElapsed;
    }

    /**
     * @dev See {IMultiTokenVault-setCurrentTimePeriodsElapsed}
     */
    function setCurrentTimePeriodsElapsed(uint256 currentTimePeriodsElapsed_) public virtual {
        currentPeriodElapsed = currentTimePeriodsElapsed_;
    }

    function _emptyBytesArray() internal pure returns (bytes[] memory) {
        return new bytes[](0);
    }

    // ===================================================================================
    // ====================================== ADDED ======================================
    // ===================================================================================

    // ========================= IMultiTokenVault - New =========================
    function maxDepositAtPeriod(address, /* receiver */ uint256 /* depositPeriod */ )
        public
        pure
        returns (uint256 /* maxAssets */ )
    {
        revert MultiTokenVault__UnsupportedFunction("maxDepositAtPeriod");
    }

    function maxRedeemAtPeriod(address, /* owner */ uint256 /* depositPeriod */ )
        public
        pure
        returns (uint256 /* maxShares */ )
    {
        revert MultiTokenVault__UnsupportedFunction("maxRedeemAtPeriod");
    }

    function totalAssets() public pure returns (uint256 /* totalAssets */ ) {
        revert MultiTokenVault__UnsupportedFunction("totalAssets");
    }
}
