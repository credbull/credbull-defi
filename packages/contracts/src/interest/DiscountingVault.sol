// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { CalcDiscounted } from "@credbull/interest/CalcDiscounted.sol";
import { CalcInterestMetadata } from "@credbull/interest/CalcInterestMetadata.sol";
import { IYieldStrategy } from "@credbull/strategy/IYieldStrategy.sol";
import { IERC5679Ext1155 } from "@credbull/interest/IERC5679Ext1155.sol";

import { MultiTokenVault } from "@credbull/interest/MultiTokenVault.sol";

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title DiscountVault
 * @dev A vault that uses SimpleInterest and Discounting to calculate shares per asset.
 *      The vault manages deposits and redemptions based on elapsed time periods and applies simple interest calculations.
 */
contract DiscountingVault is MultiTokenVault, CalcInterestMetadata {
    using Math for uint256;

    IYieldStrategy public immutable YIELD_STRATEGY;
    uint256 public immutable TENOR;

    error DiscountingVault__DepositPeriodNotDerivable(uint256 redeemPeriod, uint256 tenor);

    struct DiscountingVaultParams {
        IERC20Metadata asset;
        IERC5679Ext1155 depositLedger;
        IYieldStrategy yieldStrategy;
        uint256 interestRatePercentageScaled;
        uint256 frequency;
        uint256 tenor;
    }

    /**
     * @notice Constructor to initialize the DiscountVault
     */
    constructor(DiscountingVaultParams memory params)
        MultiTokenVault(params.asset, params.depositLedger)
        CalcInterestMetadata(params.interestRatePercentageScaled, params.frequency, params.asset.decimals())
    {
        YIELD_STRATEGY = params.yieldStrategy;
        TENOR = params.tenor;
    }

    // =============== IDiscountVault ===============

    /**
     * @dev See {CalcSimpleInterest-calcInterest}
     */
    function calcYield(uint256 principal, uint256 fromPeriod, uint256 toPeriod)
        public
        view
        override
        returns (uint256 yield)
    {
        return YIELD_STRATEGY.calcYield(address(this), principal, fromPeriod, toPeriod);
    }

    /**
     * @dev See {CalcDiscounted-calcPriceFromInterest}
     */
    function calcPrice(uint256 numPeriodsElapsed) public view virtual returns (uint256 price) {
        return YIELD_STRATEGY.calcPrice(address(this), numPeriodsElapsed);
    }

    /**
     * @notice Converts a given amount of shares to principal based on the given deposit time period.
     * @param shares The amount of shares to convert.
     * @param depositPeriod The period at which the shares were deposited.
     * @return principal The principal corresponding to the shares at the specified time period.
     */
    function _convertToPrincipalAtDepositPeriod(uint256 shares, uint256 depositPeriod)
        internal
        view
        returns (uint256 principal)
    {
        if (shares < SCALE) return 0; // no principal for fractional shares

        uint256 price = calcPrice(depositPeriod);

        return CalcDiscounted.calcPrincipalFromDiscounted(shares, price, SCALE);
    }

    // =============== Deposit ===============

    /**
     * @dev See {IMultiTokenVault-convertToSharesForDepositPeriod}
     */
    function convertToSharesForDepositPeriod(uint256 assets, uint256 depositPeriod)
        public
        view
        override
        returns (uint256 shares)
    {
        if (assets < SCALE) return 0; // no shares for fractional assets

        uint256 price = calcPrice(depositPeriod);

        return CalcDiscounted.calcDiscounted(assets, price, SCALE);
    }

    // =============== Redeem ===============

    /**
     * @dev See {IMultiTokenVault-convertToAssetsForDepositPeriod}
     */
    function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod, uint256 redeemPeriod)
        public
        view
        override
        returns (uint256 assets)
    {
        if (shares < SCALE) return 0; // no assets for fractional shares

        if (redeemPeriod < depositPeriod) return 0; // trying to redeem before depositPeriod

        uint256 _principal = _convertToPrincipalAtDepositPeriod(shares, depositPeriod);

        return _principal + calcYield(_principal, depositPeriod, redeemPeriod);
    }

    /**
     * @notice Converts a given amount of shares to assets based on an implied deposit period.
     * @param shares The amount of shares to convert.
     * @param redeemPeriod The time period for redeem.
     * @return assets The number of assets corresponding to the shares at the specified redeem period.
     */
    function _convertToAssetsForImpliedDepositPeriod(uint256 shares, uint256 redeemPeriod)
        internal
        view
        returns (uint256 assets)
    {
        // Redeeming before TENOR - return the discounted amount (no interest).
        if (redeemPeriod < TENOR) return 0;

        uint256 impliedDepositPeriod = _getDepositPeriodFromRedeemPeriod(redeemPeriod);

        return convertToAssetsForDepositPeriod(shares, impliedDepositPeriod, redeemPeriod);
    }

    // =============== Utility ===============

    // MUST hold that depositPeriod + TENOR = redeemPeriod
    function _getDepositPeriodFromRedeemPeriod(uint256 redeemPeriod) internal view returns (uint256 depositPeriod) {
        if (redeemPeriod < TENOR) {
            revert DiscountingVault__DepositPeriodNotDerivable(redeemPeriod, TENOR); // unable to derive deposit period
        }

        return redeemPeriod - TENOR;
    }
}
