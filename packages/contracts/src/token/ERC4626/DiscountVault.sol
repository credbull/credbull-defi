// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { CalcDiscounted } from "@credbull/yield/CalcDiscounted.sol";
import { ICalcInterestMetadata } from "@credbull/yield/ICalcInterestMetadata.sol";
import { CalcSimpleInterest } from "@credbull/yield/CalcSimpleInterest.sol";
import { IDiscountVault } from "@credbull/token/ERC4626/IDiscountVault.sol";

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// TODO - use the upgradeable versions of the contractds
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title SimpleInterestVault
 * @dev A vault that uses SimpleInterest to calculate shares per asset.
 *      The vault manages deposits and redemptions based on elapsed time periods and applies simple interest calculations.
 */
contract DiscountVault is IDiscountVault, ICalcInterestMetadata, ERC4626 {
    using Math for uint256;

    // TODO - remove these after inheriting from CalcInterestMetaData directly
    uint256 public RATE_PERCENT_SCALED; // rate in percentage * scale.  e.g., at scale 1e3, 5% = 5000.
    uint256 public FREQUENCY;
    uint256 public SCALE;
    // end TODO - remove these after inheriting from CalcInterestMetaData directly

    error RedeemTimePeriodNotSupported(uint256 currentPeriod, uint256 redeemPeriod);

    uint256 public currentTimePeriodsElapsed = 0; // the current number of time periods elapsed

    uint256 public immutable TENOR;

    constructor(IERC20Metadata asset, uint256 interestRatePercentage_, uint256 frequency_, uint256 tenor_)
        ERC4626(asset)
        ERC20("Simple Interest Rate Claim", "cSIR")
    {
        RATE_PERCENT_SCALED = interestRatePercentage_;
        FREQUENCY = frequency_;
        SCALE = 10 ** asset.decimals();
        TENOR = tenor_;
    }

    /// @inheritdoc IDiscountVault
    function calcPrice(uint256 numTimePeriodsElapsed) public view returns (uint256 priceScaled) {
        uint256 interest = calcYield(SCALE, numTimePeriodsElapsed); // principal of 1 at SCALE

        return SCALE + interest;
    }

    function calcPrincipalFromDiscounted(uint256 discounted, uint256 numTimePeriodsElapsed)
        public
        view
        returns (uint256 principal)
    {
        uint256 price = calcPrice(numTimePeriodsElapsed);

        return CalcDiscounted.calcPrincipalFromDiscounted(discounted, price, SCALE);
    }

    /// @inheritdoc IDiscountVault
    function calcYield(uint256 principal, uint256 numTimePeriodsElapsed) public view returns (uint256 interest) {
        return CalcSimpleInterest.calcInterest(principal, RATE_PERCENT_SCALED, numTimePeriodsElapsed, FREQUENCY, SCALE);
    }

    // =============== Deposit ===============

    /// @inheritdoc IDiscountVault
    function convertToSharesAtPeriod(uint256 assets, uint256 numTimePeriodsElapsed)
        public
        view
        returns (uint256 shares)
    {
        if (assets < SCALE) return 0; // no shares for fractional assets

        uint256 price = calcPrice(numTimePeriodsElapsed);

        return CalcDiscounted.calcDiscounted(assets, price, SCALE);
    }

    /// @inheritdoc ERC4626
    function previewDeposit(uint256 assets) public view override(ERC4626, IERC4626) returns (uint256 shares) {
        return convertToShares(assets);
    }

    /// @inheritdoc ERC4626
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
            revert RedeemTimePeriodNotSupported(currentTimePeriodsElapsed, redeemTimePeriod);
        }

        return redeem(shares, receiver, owner);
    }

    /// @inheritdoc IDiscountVault
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

    function _convertToPrincipalAtDepositPeriod(uint256 shares, uint256 depositTimePeriod)
        internal
        view
        returns (uint256 principal)
    {
        if (shares < SCALE) return 0; // no assets for fractional shares

        uint256 _principal = calcPrincipalFromDiscounted(shares, depositTimePeriod);

        return _principal;
    }

    /// @inheritdoc ERC4626
    function previewRedeem(uint256 shares) public view override(ERC4626, IERC4626) returns (uint256 assets) {
        return convertToAssets(shares);
    }

    /// @inheritdoc ERC4626
    function convertToAssets(uint256 shares) public view override(ERC4626, IERC4626) returns (uint256 assets) {
        return convertToAssetsAtPeriod(shares, currentTimePeriodsElapsed);
    }

    // =============== Withdraw ===============

    /// @inheritdoc ERC4626
    function previewWithdraw(uint256 assets) public view override(ERC4626, IERC4626) returns (uint256 shares) {
        if (assets < SCALE) return 0; // no shares for fractional assets

        // withdraw before TENOR - not enough time periods to calculate Discounted properly
        if (currentTimePeriodsElapsed < TENOR) return 0;

        uint256 price = calcPrice(currentTimePeriodsElapsed - TENOR);

        return CalcDiscounted.calcDiscounted(assets, price, SCALE);
    }

    // =============== ERC4626 and ERC20 ===============

    /// @inheritdoc ERC4626
    function decimals() public view virtual override(ERC4626, IERC20Metadata) returns (uint8) {
        return ERC4626.decimals();
    }

    // =============== CalcInterestMetadata ===============
    /// @notice Returns the frequency of interest application.
    function frequency() public view virtual returns (uint256 frequency_) {
        return FREQUENCY;
    }

    /// @notice Returns the annual interest rate as a percentage, scaled.
    function rateScaled() public view virtual returns (uint256 ratePercentageScaled_) {
        return RATE_PERCENT_SCALED;
    }

    /// @notice Returns the scale factor for calculations (e.g., 10^18 for 18 decimals).
    function scale() public view virtual returns (uint256 scale_) {
        return SCALE;
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
