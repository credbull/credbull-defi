// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IMultiTokenVault } from "@credbull/interest/IMultiTokenVault.sol";
import { IERC1155MintAndBurnable } from "@credbull/interest/IERC1155MintAndBurnable.sol";
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

    IERC1155MintAndBurnable public immutable DEPOSITS;
    uint256 public currentTimePeriodsElapsed = 0; // the current number of time periods elapsed

    error MultiTokenVault__UnsupportedFunction(string functionName);
    error MultiTokenVault__ExceededMaxRedeem(address owner, uint256 depositPeriod, uint256 shares, uint256 max);

    /**
     * @notice Constructor to initialize the vault with asset and deposit ledger.
     * @param asset The ERC20 token that represents the underlying asset.
     * @param depositLedger The ledger contract managing deposits.
     */
    constructor(IERC20Metadata asset, IERC1155MintAndBurnable depositLedger)
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
        DEPOSITS.mint(receiver, getCurrentTimePeriodsElapsed(), shares, "");
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
    ) public returns (uint256 assets) {
        if (currentTimePeriodsElapsed != redeemPeriod) {
            revert IProduct.RedeemTimePeriodNotSupported(currentTimePeriodsElapsed, redeemPeriod);
        }
        uint256 maxShares = getSharesAtPeriod(owner, depositPeriod);
        if (shares > maxShares) {
            revert MultiTokenVault__ExceededMaxRedeem(owner, depositPeriod, shares, maxShares);
        }

        DEPOSITS.burn(owner, depositPeriod, shares); // deposit specific

        return redeem(shares, receiver, owner); // fungible
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
    function setCurrentTimePeriodsElapsed(uint256 _currentTimePeriodsElapsed) public virtual {
        currentTimePeriodsElapsed = _currentTimePeriodsElapsed;
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

    // ========================= IERC4626 =========================

    /**
     * @dev Unsupported function for converting shares to assets.
     */
    function convertToAssets(uint256) public pure override returns (uint256) {
        revert MultiTokenVault__UnsupportedFunction("convertToAssets");
    }

    /**
     * @dev Unsupported function for previewing withdrawal.
     */
    function previewWithdraw(uint256) public pure override returns (uint256) {
        revert MultiTokenVault__UnsupportedFunction("previewWithdraw");
    }

    /**
     * @dev Unsupported function for withdrawing assets.
     */
    function withdraw(uint256, address, address) public virtual override returns (uint256) {
        revert MultiTokenVault__UnsupportedFunction("withdraw");
    }

    /**
     * @dev Redeems shares, using the current period as the deposit period.
     * @param shares The number of shares to redeem.
     * @param receiver The address to receive the redeemed assets.
     * @param owner The address that owns the shares.
     * @return assets The amount of assets redeemed.
     */
    function redeem(uint256 shares, address receiver, address owner) public virtual override returns (uint256 assets) {
        return ERC4626.redeem(shares, receiver, owner);
    }
}
