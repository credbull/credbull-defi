// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IMultiTokenVault } from "@credbull/interest/IMultiTokenVault.sol";
import { IProduct } from "@credbull/interest/IProduct.sol";

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title DiscountVault
 * @dev A vault that uses SimpleInterest and Discounting to calculate shares per asset.
 *      The vault manages deposits and redemptions based on elapsed time periods and applies simple interest calculations.
 */
abstract contract MultiTokenVault is IMultiTokenVault, ERC4626, ERC20Burnable {
    using Math for uint256;

    uint256 public currentTimePeriodsElapsed = 0; // the current number of time periods elapsed

    error UnsupportedFunction(string functionName);

    /**
     * @notice Constructor to initialize the SimpleInterestVault with asset, interest rate, frequency, and tenor.
     * @param asset The ERC20 token that represents the underlying asset.
     */
    constructor(IERC20Metadata asset) ERC4626(asset) ERC20("Multi Token Vault", "cMTV") { }

    // =============== View ===============

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
     *  @dev See {IMultiTokenVault-previewDeposit}
     */
    function previewDeposit(uint256 assets) public view override(ERC4626, IMultiTokenVault) returns (uint256 shares) {
        return convertToShares(assets);
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

    function previewRedeemForDepositPeriod(uint256 shares, uint256 depositPeriod, uint256 redeemPeriod)
        public
        view
        returns (uint256 assets)
    {
        return convertToAssetsForDepositPeriod(shares, depositPeriod, redeemPeriod);
    }

    function redeemForDepositPeriod(
        uint256 shares,
        address receiver,
        address owner,
        uint256, /* depositPeriod */
        uint256 redeemPeriod
    ) public returns (uint256 assets) {
        if (currentTimePeriodsElapsed != redeemPeriod) {
            revert IProduct.RedeemTimePeriodNotSupported(currentTimePeriodsElapsed, redeemPeriod);
        }
        // TODO lucasia - should only redeem for the specific Deposit period
        return redeem(shares, receiver, owner);
    }

    // MUST assume redeemPeriod = getCurrentTimePeriod()
    function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod)
        public
        view
        returns (uint256 assets)
    {
        return convertToAssetsForDepositPeriod(shares, depositPeriod, currentTimePeriodsElapsed);
    }

    // MUST assume redeemPeriod = getCurrentTimePeriod()
    function previewRedeemForDepositPeriod(uint256 shares, uint256 depositPeriod)
        public
        view
        returns (uint256 assets)
    {
        return previewRedeemForDepositPeriod(shares, depositPeriod, currentTimePeriodsElapsed);
    }

    // MUST assume redeemPeriod = getCurrentTimePeriod()
    function redeemForDepositPeriod(uint256 shares, address receiver, address owner, uint256 depositPeriod)
        public
        returns (uint256 assets)
    {
        return redeemForDepositPeriod(shares, receiver, owner, depositPeriod, currentTimePeriodsElapsed);
    }

    // =============== ERC4626 and ERC20 ===============

    /**
     * @notice Returns the number of decimals used by the token.
     * @return The number of decimals.
     */
    function decimals() public view virtual override(ERC20, ERC4626) returns (uint8) {
        return ERC4626.decimals();
    }

    // =============== Utility ===============

    /**
     * @notice Returns the current number of time periods elapsed.
     * @return The current time periods elapsed.
     */
    function getCurrentTimePeriodsElapsed() public view virtual returns (uint256) {
        return currentTimePeriodsElapsed;
    }

    /**
     * @notice Sets the current number of time periods elapsed.
     * @param _currentTimePeriodsElapsed The new number of time periods elapsed.
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

    // not okay - shares from what deposit?!?
    function convertToAssets(uint256 /* shares */ ) public pure override returns (uint256 /* assets */ ) {
        revert UnsupportedFunction("convertToAssets");
    }

    // mint related - hmm...
    //    function maxMint(address receiver) external view returns (uint256 maxShares);
    //    function previewMint(uint256 shares) external view returns (uint256 assets);
    //    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    //    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    // not okay - assets from what deposit?!?
    function previewWithdraw(uint256 /* assets */ ) public pure override returns (uint256 /* shares */ ) {
        revert UnsupportedFunction("previewWithdraw");
    }

    // not okay - assets from what deposit?!?
    function withdraw(uint256, /* assets */ address, /* receiver */ address /* owner */ )
        public
        virtual
        override
        returns (uint256 /* shares */ )
    {
        revert UnsupportedFunction("withdraw");
    }

    //    function maxRedeem(address owner) external view returns (uint256 maxShares);

    // not okay - shares from what deposit?!?
    // TODO - lucasia replace this with a depositPeriod aware version
    // this will call the previewRedeem(uint256 shares) - depositPeriod will be implied from the currentPeriod
    function redeem(uint256 shares, address receiver, address owner) public virtual override returns (uint256 assets) {
        // revert UnsupportedFunction("redeem");
        return ERC4626.redeem(shares, receiver, owner);
    }
}
