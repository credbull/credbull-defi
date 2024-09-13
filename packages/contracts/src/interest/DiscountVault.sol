// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { CalcDiscounted } from "@credbull/interest/CalcDiscounted.sol";
import { CalcInterestMetadata } from "@credbull/interest/CalcInterestMetadata.sol";
import { CalcSimpleInterest } from "@credbull/interest/CalcSimpleInterest.sol";
import { IDiscountVault } from "@credbull/interest/IDiscountVault.sol";

import { IProduct } from "@credbull/interest/IProduct.sol";

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title SimpleInterestVault
 * @dev A vault that uses SimpleInterest to calculate shares per asset.
 *      The vault manages deposits and redemptions based on elapsed time periods and applies simple interest calculations.
 */
contract DiscountVault is IDiscountVault, CalcInterestMetadata, ERC4626, ERC20Burnable {
    using Math for uint256;

    uint256 public currentTimePeriodsElapsed = 0; // the current number of time periods elapsed

    // The number of time periods for vault redemption.
    // Should use the same time unit (day/month/year) as the interest frequency.
    uint256 public immutable TENOR;

    /**
     * @notice Constructor to initialize the SimpleInterestVault with asset, interest rate, frequency, and tenor.
     * @param asset The ERC20 token that represents the underlying asset.
     * @param interestRatePercentage The annual interest rate as a percentage.
     * @param frequency The number of interest periods in a year.
     * @param tenor The duration of the lock period in the same unit as the interest frequency.
     */
    constructor(IERC20Metadata asset, uint256 interestRatePercentage, uint256 frequency, uint256 tenor)
        CalcInterestMetadata(interestRatePercentage, frequency, asset.decimals())
        ERC4626(asset)
        ERC20("Simple Interest Rate Claim", "cSIR")
    {
        TENOR = tenor;
    }

    /**
     * @notice Calculates the price for a given number of periods elapsed.
     * Price represents the accrued interest over time for a Principal of 1.
     * @dev - return value is scaled as Price * SCALE.  For example: Price=1.01 and Scale=100 returns 101
     * @param numTimePeriodsElapsed The number of time periods that have elapsed.
     * @return priceScaled The price scaled by the internal scale factor.
     */
    function calcPrice(uint256 numTimePeriodsElapsed) public view returns (uint256 priceScaled) {
        uint256 interest = CalcSimpleInterest.calcInterest(SCALE, numTimePeriodsElapsed, INTEREST_RATE, FREQUENCY);

        return SCALE + interest;
    }

    /**
     * @notice See {CalcDiscounted-calcPrincipalFromDiscounted}
     */
    function calcPrincipalFromDiscounted(uint256 discounted, uint256 numTimePeriodsElapsed)
        public
        view
        returns (uint256 principal)
    {
        uint256 price = calcPrice(numTimePeriodsElapsed);

        return CalcDiscounted.calcPrincipalFromDiscounted(discounted, price, SCALE);
    }

    /**
     * @notice See {CalcSimpleInterest-calcInterest}
     */
    function calcYield(uint256 principal, uint256 numTimePeriodsElapsed) public view returns (uint256 interest) {
        return CalcSimpleInterest.calcInterest(principal, numTimePeriodsElapsed, INTEREST_RATE, FREQUENCY);
    }

    // =============== Deposit ===============

    /**
     * @notice Converts a given amount of assets to shares based on a specific time period.
     * @param assets The amount of assets to convert.
     * @param numTimePeriodsElapsed The number of time periods elapsed.
     * @return shares The number of shares corresponding to the assets at the specified time period.
     */
    function convertToSharesAtPeriod(uint256 assets, uint256 numTimePeriodsElapsed)
        public
        view
        returns (uint256 shares)
    {
        if (assets < SCALE) return 0; // no shares for fractional assets

        uint256 price = calcPrice(numTimePeriodsElapsed);

        return CalcDiscounted.calcDiscounted(assets, price, SCALE);
    }

    /**
     * @notice Previews the number of shares that would be minted for a given deposit amount.
     * @param assets The amount of assets to deposit.
     * @return shares The number of shares that would be minted.
     */
    function previewDeposit(uint256 assets) public view override(ERC4626, IERC4626) returns (uint256 shares) {
        return convertToShares(assets);
    }

    /**
     * @notice Converts a given amount of assets to shares using the current time periods elapsed.
     * @param assets The amount of assets to convert.
     * @return shares The number of shares corresponding to the assets.
     */
    function convertToShares(uint256 assets) public view override(ERC4626, IERC4626) returns (uint256 shares) {
        return convertToSharesAtPeriod(assets, currentTimePeriodsElapsed);
    }

    // =============== Redeem ===============

    /**
     * @notice Redeems shares for assets at a specific time period, transferring the assets to the receiver.
     * @param shares The number of shares to redeem.
     * @param receiver The address receiving the assets.
     * @param owner The address that owns the shares.
     * @param redeemTimePeriod The time period at which the shares are redeemed.
     * @return assets The number of assets transferred to the receiver.
     */
    function redeemAtPeriod(uint256 shares, address receiver, address owner, uint256 redeemTimePeriod)
        public
        virtual
        returns (uint256 assets)
    {
        if (currentTimePeriodsElapsed != redeemTimePeriod) {
            revert IProduct.RedeemTimePeriodNotSupported(currentTimePeriodsElapsed, redeemTimePeriod);
        }

        return redeem(shares, receiver, owner);
    }

    /**
     * @notice Converts a given amount of shares to assets based on a specific time period.
     * @param shares The amount of shares to convert.
     * @param numTimePeriodsElapsed The number of time periods elapsed.
     * @return assets The number of assets corresponding to the shares at the specified time period.
     */
    function convertToAssetsAtPeriod(uint256 shares, uint256 numTimePeriodsElapsed)
        public
        view
        returns (uint256 assets)
    {
        if (shares < SCALE) return 0; // no assets for fractional shares

        // redeeming before TENOR - give back the Discounted Amount.
        // This is a slash of Principal (and no Interest).
        // TODO - need to account for deposits after TENOR.  e.g. 30 day tenor, deposit on day 31 and redeem on day 32.
        if (numTimePeriodsElapsed < TENOR) return 0;

        uint256 impliedNumTimePeriodsAtDeposit = (numTimePeriodsElapsed - TENOR);

        uint256 _principal = _convertToPrincipalAtDepositPeriod(shares, impliedNumTimePeriodsAtDeposit);

        return _principal + calcYield(_principal, TENOR);
    }

    /**
     * @notice Converts a given amount of shares to assets based on the given deposit time period
     * @param shares The amount of shares to convert.
     * @param depositTimePeriod The period at deposit
     * @return principal The principal corresponding to the shares at the specified time period.
     */
    function _convertToPrincipalAtDepositPeriod(uint256 shares, uint256 depositTimePeriod)
        internal
        view
        returns (uint256 principal)
    {
        if (shares < SCALE) return 0; // no assets for fractional shares

        uint256 _principal = calcPrincipalFromDiscounted(shares, depositTimePeriod);

        return _principal;
    }

    /**
     * @notice Previews the number of assets that would be redeemed for a given number of shares.
     * @param shares The number of shares to redeem.
     * @return assets The number of assets that would be redeemed.
     */
    function previewRedeem(uint256 shares) public view override(ERC4626, IERC4626) returns (uint256 assets) {
        return convertToAssets(shares);
    }

    /**
     * @notice Converts a given amount of shares to assets using the current time periods elapsed.
     * @param shares The amount of shares to convert.
     * @return assets The number of assets corresponding to the shares.
     */
    function convertToAssets(uint256 shares) public view override(ERC4626, IERC4626) returns (uint256 assets) {
        return convertToAssetsAtPeriod(shares, currentTimePeriodsElapsed);
    }

    // =============== Withdraw ===============

    /**
     * @notice Previews the number of shares to be burned if withdrawing the given number of assets
     * @param assets The number of assets to withdraw.
     * @return shares The number of shares that would be burned
     */
    function previewWithdraw(uint256 assets) public view override(ERC4626, IERC4626) returns (uint256 shares) {
        if (assets < SCALE) return 0; // no shares for fractional assets

        // withdraw before TENOR - not enough time periods to calculate Discounted properly
        if (currentTimePeriodsElapsed < TENOR) return 0;

        uint256 price = calcPrice(currentTimePeriodsElapsed - TENOR);

        return CalcDiscounted.calcDiscounted(assets, price, SCALE);
    }

    // =============== ERC4626 and ERC20 ===============

    /**
     * @notice Returns the number of decimals used by the token.
     * @return The number of decimals.
     */
    function decimals() public view virtual override(ERC20, ERC4626, IERC20Metadata) returns (uint8) {
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
     * @notice Returns the tenor (lock period) of the vault.
     * @return tenor The tenor value.
     */
    function getTenor() public view returns (uint256 tenor) {
        return TENOR;
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
}
