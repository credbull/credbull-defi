// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { ISimpleInterest } from "@credbull-spike/contracts/ian/interfaces/ISimpleInterest.sol";
import { SimpleInterest } from "@credbull-spike/contracts/ian/fixed/SimpleInterest.sol";
import { IERC4626Interest } from "@credbull-spike/contracts/ian/interfaces/IERC4626Interest.sol";
import { IProduct } from "@credbull-spike/contracts/IProduct.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

import { Math } from "@openzeppelin/contracts//utils/math/Math.sol";

/**
 * @title SimpleInterestVault
 * @dev A vault that uses SimpleInterest to calculate shares per asset.
 *      The vault manages deposits and redemptions based on elapsed time periods and applies simple interest calculations.
 */
contract SimpleInterestVault is IERC4626Interest, SimpleInterest, ERC4626, IProduct, ERC20Burnable {
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
    constructor(IERC20 asset, uint256 interestRatePercentage, uint256 frequency, uint256 tenor)
    SimpleInterest(interestRatePercentage, frequency)
    ERC4626(asset)
    ERC20("Simple Interest Rate Claim", "cSIR")
    {
        TENOR = tenor;
    }

    // =============== Deposit ===============

    /**
     * @notice Deposits assetsInWei into the vault and mints corresponding shares to the receiver.
     * @param assetsInWei The amount of assets to deposit.
     * @param receiver The address receiving the minted shares.
     * @return sharesInWei The number of shares minted to the receiver.
     */
    function deposit(uint256 assetsInWei, address receiver)
    public
    virtual
    override(IERC4626, ERC4626, IProduct)
    returns (uint256 sharesInWei)
    {
        return ERC4626.deposit(assetsInWei, receiver);
    }

    /**
     * @notice Converts a given amount of assets to shares based on a specific time period.
     * @param assetsInWei The amount of assets to convert.
     * @param numTimePeriodsElapsed The number of time periods elapsed.
     * @return sharesInWei The number of shares corresponding to the assets at the specified time period.
     */
    function convertToSharesAtPeriod(uint256 assetsInWei, uint256 numTimePeriodsElapsed)
    public
    view
    returns (uint256 sharesInWei)
    {
        if (assetsInWei < SCALE) return 0; // no shares for fractional assets

        return calcDiscounted(assetsInWei, numTimePeriodsElapsed);
    }

    /**
     * @notice Previews the number of shares that would be minted for a given deposit amount.
     * @param assetsInWei The amount of assets to deposit.
     * @return sharesInWei The number of shares that would be minted.
     */
    function previewDeposit(uint256 assetsInWei)
    public
    view
    override(ERC4626, IERC4626)
    returns (uint256 sharesInWei)
    {
        return convertToShares(assetsInWei);
    }

    /**
     * @notice Converts a given amount of assets to shares using the current time periods elapsed.
     * @param assetsInWei The amount of assets to convert.
     * @return sharesInWei The number of shares corresponding to the assets.
     */
    function convertToShares(uint256 assetsInWei)
    public
    view
    override(ERC4626, IERC4626)
    returns (uint256 sharesInWei)
    {
        return convertToSharesAtPeriod(assetsInWei, currentTimePeriodsElapsed);
    }

    // =============== Redeem ===============

    /**
     * @notice Redeems shares for assets, transferring the assets to the receiver.
     * @param sharesInWei The number of shares to redeem.
     * @param receiver The address receiving the assets.
     * @param owner The address that owns the shares.
     * @return assets The number of assets transferred to the receiver.
     */
    function redeem(uint256 sharesInWei, address receiver, address owner)
    public
    virtual
    override(IERC4626, ERC4626, IProduct)
    returns (uint256 assets)
    {
        return ERC4626.redeem(sharesInWei, receiver, owner);
    }

    /**
     * @notice Redeems shares for assets at a specific time period, transferring the assets to the receiver.
     * @param sharesInWei The number of shares to redeem.
     * @param receiver The address receiving the assets.
     * @param owner The address that owns the shares.
     * @param redeemTimePeriod The time period at which the shares are redeemed.
     * @return assetsInWei The number of assets transferred to the receiver.
     */
    function redeemAtPeriod(uint256 sharesInWei, address receiver, address owner, uint256 redeemTimePeriod)
    external
    returns (uint256 assetsInWei)
    {
        if (currentTimePeriodsElapsed != redeemTimePeriod) {
            revert RedeemTimePeriodNotSupported(currentTimePeriodsElapsed, redeemTimePeriod);
        }

        return redeem(sharesInWei, receiver, owner);
    }

    /**
     * @notice Converts a given amount of shares to assets based on a specific time period.
     * @param sharesInWei The amount of shares to convert.
     * @param numTimePeriodsElapsed The number of time periods elapsed.
     * @return assetsInWei The number of assets corresponding to the shares at the specified time period.
     */
    function convertToAssetsAtPeriod(uint256 sharesInWei, uint256 numTimePeriodsElapsed)
    public
    view
    returns (uint256 assetsInWei)
    {
        if (sharesInWei < SCALE) return 0; // no assets for fractional shares

        // Trying to redeem before TENOR - just give back the Discounted Amount.
        // This is a slash of Principal (and no Interest).
        if (numTimePeriodsElapsed < TENOR) return sharesInWei;

        uint256 principal = _calcPrincipalFromSharesAtPeriod(sharesInWei, numTimePeriodsElapsed);

        return principal + calcInterest(principal, TENOR);
    }

    /**
     * @notice Internal function to calculate the principal from shares based on a specific time period.
     * @param sharesInWei The amount of shares to convert.
     * @param numTimePeriodsElapsed The number of time periods elapsed.
     * @return principal The principal amount corresponding to the shares.
     */
    function _calcPrincipalFromSharesAtPeriod(uint256 sharesInWei, uint256 numTimePeriodsElapsed)
    internal
    view
    returns (uint256 principal)
    {
        if (sharesInWei < SCALE) return 0; // no assets for fractional shares

        // Trying to redeem before TENOR - just give back the Discounted Amount.
        // This is a slash of Principal (and no Interest).
        if (numTimePeriodsElapsed < TENOR) return sharesInWei;

        uint256 impliedNumTimePeriodsAtDeposit = (numTimePeriodsElapsed - TENOR);

        uint256 _principal = calcPrincipalFromDiscounted(sharesInWei, impliedNumTimePeriodsAtDeposit);

        return _principal;
    }

    /**
     * @notice Previews the number of assets that would be redeemed for a given number of shares.
     * @param sharesInWei The number of shares to redeem.
     * @return assetsInWei The number of assets that would be redeemed.
     */
    function previewRedeem(uint256 sharesInWei) public view override(ERC4626, IERC4626) returns (uint256 assetsInWei) {
        return convertToAssets(sharesInWei);
    }

    /**
     * @notice Converts a given amount of shares to assets using the current time periods elapsed.
     * @param sharesInWei The amount of shares to convert.
     * @return assetsInWei The number of assets corresponding to the shares.
     */
    function convertToAssets(uint256 sharesInWei)
    public
    view
    override(ERC4626, IERC4626)
    returns (uint256 assetsInWei)
    {
        return convertToAssetsAtPeriod(sharesInWei, currentTimePeriodsElapsed);
    }

    // =============== ERC4626 and ERC20 ===============

    /**
     * @notice Returns the number of decimals used by the token.
     * @return The number of decimals.
     */
    function decimals() public view virtual override(ERC20, ERC4626, IERC20Metadata) returns (uint8) {
        return ERC4626.decimals();
    }

    /**
     * @notice Internal function to burn tokens from an account.
     * @param account The account from which to burn tokens.
     * @param value The amount of tokens to burn.
     */
    function _burnInternal(address account, uint256 value) internal virtual {
        _burn(account, value);
    }

    // =============== Utility ===============

    /**
     * @notice Returns the current number of time periods elapsed.
     * @return The current time periods elapsed.
     */
    function getCurrentTimePeriodsElapsed()
    public
    view
    virtual
    override(IERC4626Interest, IProduct)
    returns (uint256)
    {
        return currentTimePeriodsElapsed;
    }

    /**
     * @notice Sets the current number of time periods elapsed.
     * @param _currentTimePeriodsElapsed The new number of time periods elapsed.
     */
    function setCurrentTimePeriodsElapsed(uint256 _currentTimePeriodsElapsed)
    public
    virtual
    override(IERC4626Interest, IProduct)
    {
        currentTimePeriodsElapsed = _currentTimePeriodsElapsed;
    }

    /**
     * @notice Returns the tenor (lock period) of the vault.
     * @return tenor The tenor value.
     */
    function getTenor() public view returns (uint256 tenor) {
        return TENOR;
    }

    // =============== IProduct Interface ===============

    /**
     * @notice Returns the frequency of interest application (number of periods in a year).
     * @return frequency The frequency value.
     */
    function getFrequency()
    public
    view
    override(ISimpleInterest, SimpleInterest, IProduct)
    returns (uint256 frequency)
    {
        return SimpleInterest.getFrequency();
    }

    /**
     * @notice Internal function to update token transfers.
     * @param from The address transferring the tokens.
     * @param to The address receiving the tokens.
     * @param value The amount of tokens being transferred.
     */
    function _update(address from, address to, uint256 value) internal override virtual {
        ERC20._update(from, to, value);
    }

    /**
     * @notice Returns the annual interest rate as a percentage.
     * @return interestRateInPercentage The interest rate as a percentage.
     */
    function getInterestInPercentage()
    public
    view
    override(ISimpleInterest, SimpleInterest, IProduct)
    returns (uint256 interestRateInPercentage)
    {
        return SimpleInterest.getInterestInPercentage();
    }
}
