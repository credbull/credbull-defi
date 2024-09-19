// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IMultiTokenVault } from "@credbull/interest/IMultiTokenVault.sol";
import { IERC5679Ext1155 } from "@credbull/interest/IERC5679Ext1155.sol";
import { IProduct } from "@credbull/interest/IProduct.sol";

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title MultiTokenVault
 * @dev A vault that uses SimpleInterest and Discounting to calculate shares per asset.
 *      The vault manages deposits and redemptions based on elapsed time periods and applies simple interest calculations.
 */
abstract contract MultiTokenVault is IMultiTokenVault, ERC4626, ERC20Burnable {
    using Math for uint256;

    IERC5679Ext1155 public immutable DEPOSITS;
    uint256 public currentTimePeriodsElapsed = 0; // the current number of time periods elapsed

    error MultiTokenVault__UnsupportedFunction(string functionName);
    error MultiTokenVault__ExceededMaxRedeem(address owner, uint256 depositPeriod, uint256 shares, uint256 max);

    /**
     * @notice Constructor to initialize the vault with asset and deposit ledger.
     * @param asset The ERC20 token that represents the underlying asset.
     * @param depositLedger The ledger contract managing deposits.
     */
    constructor(IERC20Metadata asset, IERC5679Ext1155 depositLedger)
        ERC4626(asset)
        ERC20("Multi Token Vault", "cMTV")
    {
        DEPOSITS = depositLedger;
    }

    // =============== View ===============

    /**
     * @dev See {IMultiTokenVault-getSharesAtPeriod}
     */
    function getSharesAtPeriod(address account, uint256 depositPeriod) public view returns (uint256 shares) {
        return DEPOSITS.balanceOf(account, depositPeriod);
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
    function convertToShares(uint256 assets) public view override(ERC4626, IMultiTokenVault) returns (uint256 shares) {
        return convertToSharesForDepositPeriod(assets, currentTimePeriodsElapsed);
    }

    /**
     * @dev See {IMultiTokenVault-previewDeposit}
     */
    function previewDeposit(uint256 assets) public view override(ERC4626, IMultiTokenVault) returns (uint256 shares) {
        return convertToShares(assets);
    }

    /**
     * @dev See {IMultiTokenVault-deposit}
     */
    function deposit(uint256 assets, address receiver)
        public
        virtual
        override(ERC4626, IMultiTokenVault)
        returns (uint256)
    {
        uint256 shares = super.deposit(assets, receiver);
        DEPOSITS.safeMint(receiver, getCurrentTimePeriodsElapsed(), shares, "");
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
            revert IProduct.RedeemTimePeriodNotSupported(owner, depositPeriod, redeemPeriod);
        }

        // TODO confirm rules around which day (or days) we allow redeems
        if (currentTimePeriodsElapsed != redeemPeriod) {
            revert IProduct.RedeemTimePeriodNotSupported(owner, currentTimePeriodsElapsed, redeemPeriod);
        }

        uint256 maxShares = getSharesAtPeriod(owner, depositPeriod);
        if (shares > maxShares) {
            revert MultiTokenVault__ExceededMaxRedeem(owner, depositPeriod, shares, maxShares);
        }

        DEPOSITS.burn(owner, depositPeriod, shares, _emptyBytesArray()); // deposit specific

        // logic for fungible shares below
        uint256 assets = previewRedeemForDepositPeriod(shares, depositPeriod);
        ERC4626._withdraw(_msgSender(), receiver, owner, assets, shares);

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
        return convertToAssetsForDepositPeriod(shares, depositPeriod, currentTimePeriodsElapsed);
    }

    /**
     * @dev See {IMultiTokenVault-previewRedeemForDepositPeriod}
     */
    function previewRedeemForDepositPeriod(uint256 shares, uint256 depositPeriod)
        public
        view
        returns (uint256 assets)
    {
        return previewRedeemForDepositPeriod(shares, depositPeriod, currentTimePeriodsElapsed);
    }

    /**
     * @dev See {IMultiTokenVault-redeemForDepositPeriod}
     */
    function redeemForDepositPeriod(uint256 shares, address receiver, address owner, uint256 depositPeriod)
        public
        returns (uint256 assets)
    {
        return redeemForDepositPeriod(shares, receiver, owner, depositPeriod, currentTimePeriodsElapsed);
    }

    // =============== ERC4626 and ERC20 ===============

    /**
     * @dev See {IMultiTokenVault-getAsset}
     */
    function getAsset() public view virtual returns (IERC20 asset) {
        return IERC20(ERC4626.asset());
    }

    /**
     * @dev See {ERC20-decimals}
     */
    function decimals() public view virtual override(ERC20, ERC4626) returns (uint8) {
        return ERC4626.decimals();
    }

    // =============== Utility ===============

    /**
     * @dev See {IMultiTokenVault-getCurrentTimePeriodsElapsed}
     */
    function getCurrentTimePeriodsElapsed() public view virtual returns (uint256) {
        return currentTimePeriodsElapsed;
    }

    /**
     * @dev See {IMultiTokenVault-setCurrentTimePeriodsElapsed}
     */
    function setCurrentTimePeriodsElapsed(uint256 currentTimePeriodsElapsed_) public virtual {
        currentTimePeriodsElapsed = currentTimePeriodsElapsed_;
    }

    /**
     * @notice Internal function to update token transfers.
     * @param from The address transferring the tokens.
     * @param to The address receiving the tokens.
     * @param value The amount of tokens being transferred.
     */
    function _update(address from, address to, uint256 value) internal virtual override {
        ERC20._update(from, to, value);
    }

    function _emptyBytesArray() internal pure returns (bytes[] memory) {
        return new bytes[](0);
    }

    // ========================= IERC4626 =========================

    /**
     * MUST override with logic to account for depositPeriod or revert
     * @dev See {IERC4626-convertToAssets}
     */
    function convertToAssets(uint256) public pure override returns (uint256 /* assets */ ) {
        revert MultiTokenVault__UnsupportedFunction("convertToAssets");
    }

    /**
     * MUST override with logic to account for depositPeriod or revert
     * @dev See {IERC4626-previewRedeem}
     */
    function previewRedeem(uint256 /* shares */ ) public view virtual override returns (uint256 /* assets */ ) {
        revert MultiTokenVault__UnsupportedFunction("previewRedeem");
    }

    /**
     * MUST override with logic to account for depositPeriod or revert
     * @dev See {IERC4626-redeem}
     */
    function redeem(uint256, /* shares */ address, /* receiver */ address /*owner*/ )
        public
        virtual
        override
        returns (uint256 /* assets */ )
    {
        revert MultiTokenVault__UnsupportedFunction("redeem");
    }

    /**
     * MUST override with logic to account for depositPeriod or revert
     * @dev See {IERC4626-previewWithdraw}
     */
    function previewWithdraw(uint256) public pure override returns (uint256 /* shares */ ) {
        revert MultiTokenVault__UnsupportedFunction("previewWithdraw");
    }

    /**
     * MUST override with logic to account for depositPeriod or revert
     * @dev See {IERC4626-withdraw}
     */
    function withdraw(uint256, address, address) public pure override returns (uint256 /* shares */ ) {
        revert MultiTokenVault__UnsupportedFunction("withdraw");
    }
}
