// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { CalcDiscounted } from "@credbull/yield/CalcDiscounted.sol";
import { ICalcInterestMetadata } from "@credbull/yield/ICalcInterestMetadata.sol";
import { IDiscountVault } from "@credbull/token/ERC4626/IDiscountVault.sol";
import { IYieldStrategy } from "@credbull/yield/strategy/IYieldStrategy.sol";
import { Timer } from "@credbull/timelock/Timer.sol";

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

    uint256 public _vaultStartTimestamp;

    IYieldStrategy public immutable YIELD_STRATEGY;
    uint256 public immutable TENOR;

    struct DiscountVaultParams {
        IERC20Metadata asset;
        IYieldStrategy yieldStrategy;
        uint256 interestRatePercentageScaled;
        uint256 frequency;
        uint256 tenor;
    }

    constructor(DiscountVaultParams memory params) ERC4626(params.asset) ERC20("Simple Interest Rate Claim", "cSIR") {
        YIELD_STRATEGY = params.yieldStrategy;

        RATE_PERCENT_SCALED = params.interestRatePercentageScaled;
        FREQUENCY = params.frequency;
        SCALE = 10 ** params.asset.decimals();
        TENOR = params.tenor;
    }

    /// @inheritdoc IDiscountVault
    function calcPrice(uint256 numPeriodsElapsed) public view returns (uint256 priceScaled) {
        return YIELD_STRATEGY.calcPrice(address(this), numPeriodsElapsed);
    }

    function _currentPrice() public view returns (uint256 priceScaled) {
        return calcPrice(currentPeriodsElapsed());
    }

    function calcYield(uint256 principal, uint256 toPeriod) public view returns (uint256 yield) {
        return calcYield(principal, 0, toPeriod);
    }

    /// @inheritdoc IDiscountVault
    function calcYield(uint256 principal, uint256 fromPeriod, uint256 toPeriod) public view returns (uint256 yield) {
        return YIELD_STRATEGY.calcYield(address(this), principal, fromPeriod, toPeriod);
    }

    // =============== Deposit ===============

    /// @inheritdoc ERC4626
    function _convertToShares(uint256 assets, Math.Rounding /* rounding */ )
        internal
        view
        virtual
        override
        returns (uint256 shares)
    {
        return CalcDiscounted.calcDiscounted(assets, _currentPrice(), SCALE);
    }

    // =============== Redeem ===============

    /// @inheritdoc ERC4626
    function _convertToAssets(uint256 shares, Math.Rounding /* rounding */ )
        internal
        view
        virtual
        override(ERC4626)
        returns (uint256 assets)
    {
        uint256 currentPeriodsElapsed_ = currentPeriodsElapsed();
        // redeeming before TENOR - give back the Discounted Amount.
        // This is a slash of Principal (and no Interest).
        // TODO - need to account for deposits after TENOR.  e.g. 30 day tenor, deposit on day 31 and redeem on day 32.
        if (currentPeriodsElapsed_ < TENOR) return 0;

        uint256 price = calcPrice(currentPeriodsElapsed_ - TENOR);

        uint256 _principal = CalcDiscounted.calcPrincipalFromDiscounted(shares, price, SCALE);

        return _principal + calcYield(_principal, TENOR);
    }

    // =============== Withdraw ===============

    /// @inheritdoc ERC4626
    // TODO - simplify this - should be able to reuse convert functions
    function previewWithdraw(uint256 assets) public view override(ERC4626, IERC4626) returns (uint256 shares) {
        uint256 currentPeriodsElapsed_ = currentPeriodsElapsed();

        // withdraw before TENOR - not enough time periods to calculate Discounted properly
        if (currentPeriodsElapsed_ < TENOR) return 0;

        uint256 price = calcPrice(currentPeriodsElapsed_ - TENOR);

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

    function currentPeriodsElapsed() public view virtual returns (uint256) {
        return Timer.elapsed24Hours(_vaultStartTimestamp);
    }

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
