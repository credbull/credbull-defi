// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { CalcDiscounted } from "@credbull/yield/CalcDiscounted.sol";
import { CalcInterestMetadata } from "@credbull/yield/CalcInterestMetadata.sol";
import { IYieldStrategy } from "@credbull/yield/strategy/IYieldStrategy.sol";
import { MultiTokenVault } from "@credbull/token/ERC1155/MultiTokenVault.sol";

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title DiscountingVault
 * @dev A vault that uses simple interest and discounting to manage shares and assets.
 */
contract DiscountingVault is MultiTokenVault, CalcInterestMetadata {
    using Math for uint256;

    IYieldStrategy public immutable YIELD_STRATEGY;
    uint256 public immutable TENOR;

    error DiscountingVault__DepositPeriodNotDerivable(uint256 redeemPeriod, uint256 tenor);

    struct DiscountingVaultParams {
        IERC20Metadata asset;
        IYieldStrategy yieldStrategy;
        uint256 interestRatePercentageScaled;
        uint256 frequency;
        uint256 tenor;
        address initialOwner;
    }

    /// @notice Initializes the DiscountingVault.
    constructor(DiscountingVaultParams memory params)
        MultiTokenVault(params.asset, params.initialOwner)
        CalcInterestMetadata(params.interestRatePercentageScaled, params.frequency, params.asset.decimals())
    {
        YIELD_STRATEGY = params.yieldStrategy;
        TENOR = params.tenor;
    }

    /// @notice Calculates the yield for `principal` from `fromPeriod` to `toPeriod`.
    function calcYield(uint256 principal, uint256 fromPeriod, uint256 toPeriod) public view returns (uint256 yield) {
        return YIELD_STRATEGY.calcYield(address(this), principal, fromPeriod, toPeriod);
    }

    /// @notice Calculates the price for a given number of periods elapsed.
    function calcPrice(uint256 numPeriodsElapsed) public view virtual returns (uint256 price) {
        return YIELD_STRATEGY.calcPrice(address(this), numPeriodsElapsed);
    }

    /// @notice Converts `shares` to principal based on `depositPeriod`.
    function _convertToPrincipalAtDepositPeriod(uint256 shares, uint256 depositPeriod)
        internal
        view
        returns (uint256 principal)
    {
        if (shares < SCALE) return 0; // no principal for fractional shares

        uint256 price = calcPrice(depositPeriod);
        return CalcDiscounted.calcPrincipalFromDiscounted(shares, price, SCALE);
    }

    /// @notice Converts `assets` to shares for `depositPeriod`.
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

    /// @notice Converts `shares` to assets for `depositPeriod` and `redeemPeriod`.
    function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod, uint256 redeemPeriod)
        public
        view
        override
        returns (uint256 assets)
    {
        if (shares < SCALE) return 0; // no assets for fractional shares

        if (redeemPeriod < depositPeriod) return 0; // trying to redeem before depositPeriod

        uint256 principal = _convertToPrincipalAtDepositPeriod(shares, depositPeriod);
        return principal + calcYield(principal, depositPeriod, redeemPeriod);
    }

    /// @notice Converts `shares` to assets for an implied deposit period.
    function _convertToAssetsForImpliedDepositPeriod(uint256 shares, uint256 redeemPeriod)
        internal
        view
        returns (uint256 assets)
    {
        // Redeeming before TENOR - return the discounted amount (no interest).
        if (redeemPeriod < TENOR) return 0;

        uint256 impliedDepositPeriod = _depositPeriodFromRedeemPeriod(redeemPeriod);
        return convertToAssetsForDepositPeriod(shares, impliedDepositPeriod, redeemPeriod);
    }

    // =============== Utility ===============

    /// @notice Derives `depositPeriod` from `redeemPeriod`.
    /// @dev MUST hold that depositPeriod + TENOR = redeemPeriod
    function _depositPeriodFromRedeemPeriod(uint256 redeemPeriod) internal view returns (uint256 depositPeriod) {
        if (redeemPeriod < TENOR) {
            revert DiscountingVault__DepositPeriodNotDerivable(redeemPeriod, TENOR); // unable to derive deposit period
        }

        return redeemPeriod - TENOR;
    }
}
