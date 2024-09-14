// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { CalcDiscounted } from "@credbull/interest/CalcDiscounted.sol";
import { CalcInterestMetadata } from "@credbull/interest/CalcInterestMetadata.sol";
import { CalcSimpleInterest } from "@credbull/interest/CalcSimpleInterest.sol";
import { IDiscountVault } from "@credbull/interest/IDiscountVault.sol";
import { IMultiTokenVault } from "@credbull/interest/IMultiTokenVault.sol";
import { ITenorable } from "@credbull/interest/ITenorable.sol";

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
contract DiscountVault is IDiscountVault, IMultiTokenVault, ITenorable, CalcInterestMetadata, ERC4626, ERC20Burnable {
    using Math for uint256;

    uint256 public currentTimePeriodsElapsed = 0; // the current number of time periods elapsed

    error UnsupportedFunction(string functionName);

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
     * @notice See {CalcDiscounted-calcPriceFromInterest}
     */
    function calcPrice(uint256 numPeriodsElapsed) public view virtual returns (uint256 price) {
        return CalcDiscounted.calcPriceFromInterest(numPeriodsElapsed, INTEREST_RATE, FREQUENCY, SCALE);
    }

    /**
     * @notice See {CalcDiscounted-calcPrincipalFromDiscounted}
     */
    function calcPrincipalFromDiscounted(uint256 discounted, uint256 numPeriodsElapsed)
        public
        view
        returns (uint256 principal)
    {
        uint256 price = calcPrice(numPeriodsElapsed);

        return CalcDiscounted.calcPrincipalFromDiscounted(discounted, price, SCALE);
    }

    /**
     * @notice See {CalcSimpleInterest-calcInterest}
     */
    function calcYield(uint256 principal, uint256 fromPeriod, uint256 toPeriod)
        public
        view
        returns (uint256 interest)
    {
        uint256 numPeriodsElapsed = toPeriod - fromPeriod;

        return CalcSimpleInterest.calcInterest(principal, numPeriodsElapsed, INTEREST_RATE, FREQUENCY);
    }

    /**
     * Yield for exactly tenor worth of periods
     */
    function calcYieldForTenorPeriods(uint256 principal) public view returns (uint256 interest) {
        return calcYield(principal, 0, TENOR);
    }

    // =============== Deposit ===============

    /**
     * @notice Converts a given amount of assets to shares based on a specific time period.
     * @param assets The amount of assets to convert.
     * @param depositPeriod The time period for deposit.
     * @return shares The number of shares corresponding to the assets at the specified time period.
     */
    function convertToSharesForDepositPeriod(uint256 assets, uint256 depositPeriod)
        public
        view
        returns (uint256 shares)
    {
        if (assets < SCALE) return 0; // no shares for fractional assets

        uint256 price = calcPrice(depositPeriod);

        return CalcDiscounted.calcDiscounted(assets, price, SCALE);
    }

    function convertToShares(uint256 assets) public view override(ERC4626, IMultiTokenVault) returns (uint256 shares) {
        return convertToSharesForDepositPeriod(assets, currentTimePeriodsElapsed);
    }

    function previewDeposit(uint256 assets) public view override(ERC4626, IMultiTokenVault) returns (uint256 shares) {
        return convertToShares(assets);
    }

    // =============== Redeem ===============

    /**
     * @notice Converts a given amount of shares to assets based on a specific time period.
     * @param shares The amount of shares to convert.
     * @param depositPeriod The time period of deposit
     * @param redeemPeriod The time period of redeem
     * @return assets The number of assets corresponding to the shares at the specified time period.
     */
    function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod, uint256 redeemPeriod)
        public
        view
        returns (uint256 assets)
    {
        if (shares < SCALE) return 0; // no assets for fractional shares

        uint256 _principal = _convertToPrincipalAtDepositPeriod(shares, depositPeriod);

        return _principal + calcYield(_principal, depositPeriod, redeemPeriod);
    }

    /**
     * @notice Converts a given amount of shares to assets based on a specific time period.
     * @param shares The amount of shares to convert.
     * @param redeemPeriod The time period for redeem
     * @return assets The number of assets corresponding to the shares at the specified time period.
     * // TODO - this should move to a TENORABLE version of the Vault
     */
    function convertToAssetsForImpliedDepositPeriod(uint256 shares, uint256 redeemPeriod)
        public
        view
        returns (uint256 assets)
    {
        // redeeming before TENOR - give back the Discounted Amount.
        // This is a slash of Principal (and no Interest).
        // TODO - need to account for deposits after TENOR.  e.g. 30 day tenor, deposit on day 31 and redeem on day 32.
        if (redeemPeriod < TENOR) return 0;

        uint256 impliedDepositPeriod = (redeemPeriod - TENOR);

        return convertToAssetsForDepositPeriod(shares, impliedDepositPeriod, redeemPeriod);
    }

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

    /**
     * @notice Redeems shares for assets at a specific time period, transferring the assets to the receiver.
     * @param shares The number of shares to redeem.
     * @param receiver The address receiving the assets.
     * @param owner The address that owns the shares.
     * @param redeemPeriod The time period at which the shares are redeemed.
     * @return assets The number of assets transferred to the receiver.
     */
    function redeemForImpliedDepositPeriod(uint256 shares, address receiver, address owner, uint256 redeemPeriod)
        public
        virtual
        returns (uint256 assets)
    {
        if (redeemPeriod < TENOR) return 0;

        uint256 impliedDepositPeriod = (redeemPeriod - TENOR);

        return redeemForDepositPeriod(shares, receiver, owner, impliedDepositPeriod, redeemPeriod);
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
        external
        returns (uint256 assets)
    {
        return redeemForDepositPeriod(shares, receiver, owner, depositPeriod, currentTimePeriodsElapsed);
    }

    // =============== Principal / Discounting ===============

    /**
     * @notice Converts a given amount of shares to assets based on the given deposit time period
     * @param shares The amount of shares to convert.
     * @param depositPeriod The period at deposit
     * @return principal The principal corresponding to the shares at the specified time period.
     */
    function _convertToPrincipalAtDepositPeriod(uint256 shares, uint256 depositPeriod)
        internal
        view
        returns (uint256 principal)
    {
        if (shares < SCALE) return 0; // no assets for fractional shares

        uint256 _principal = calcPrincipalFromDiscounted(shares, depositPeriod);

        return _principal;
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
    function previewRedeem(uint256 shares) public view override returns (uint256 assets) {
        // revert UnsupportedFunction("previewRedeem");
        return convertToAssetsForImpliedDepositPeriod(shares, currentTimePeriodsElapsed);
    }

    // not okay - shares from what deposit?!?
    // TODO - lucasia replace this with a depositPeriod aware version
    // this will call the previewRedeem(uint256 shares) - depositPeriod will be implied from the currentPeriod
    function redeem(uint256 shares, address receiver, address owner) public virtual override returns (uint256 assets) {
        // revert UnsupportedFunction("redeem");
        return ERC4626.redeem(shares, receiver, owner);
    }
}
