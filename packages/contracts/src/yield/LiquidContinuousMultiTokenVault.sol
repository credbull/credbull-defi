// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IYieldStrategy } from "@credbull/yield/strategy/IYieldStrategy.sol";
import { MultiTokenVault } from "@credbull/token/ERC1155/MultiTokenVault.sol";
import { TimelockAsyncUnlock } from "@credbull/timelock/TimelockAsyncUnlock.sol";
import { Timer } from "@credbull/timelock/Timer.sol";
import { TripleRateContext } from "@credbull/yield/context/TripleRateContext.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title LiquidAsyncRedeemMultiTokenVault
 * Vault with the following properties:
 * - Liquid - short-term time horizon
 * - Continuous - ongoing deposits and redeems without a maturity
 * - MultiToken - each deposit period received a different ERC1155 share token
 * - Async Redeem  - two step redeem process: request to redeem and then redeem after notice period
 * - Multiple rates - full rate on deposits held "tenor" days, reduced rates for days 1-29
 *
 * @dev Vault MUST be a Daily frequency of 360 or 365.  `depositPeriods` will be used as IERC1155 `ids`.
 * - Seconds frequency is NOT SUPPORTED.  Results in too many periods to manage as IERC155 ids
 * - Month or Annual frequency is NOT SUPPORTED.  Requires a more advanced timer e.g. an external Oracle.
 *
 */
contract LiquidContinuousMultiTokenVault is MultiTokenVault, TimelockAsyncUnlock, Timer, TripleRateContext {
    using SafeERC20 for IERC20;

    IYieldStrategy public immutable YIELD_STRATEGY; // TODO lucasia - confirm if immutable or not

    error LiquidContinuousMultiTokenVault__InvalidFrequency(uint256 frequency);

    struct VaultParams {
        IERC20Metadata asset;
        IYieldStrategy yieldStrategy;
        uint256 vaultStartTimestamp;
        uint256 redeemNoticePeriod;
        uint256 interestRatePercentageScaled;
        uint256 reducedInterestRatePercentageScaled;
        uint256 frequency; // MUST be a daily frequency, either 360 or 365
        uint256 tenor;
    }

    constructor(VaultParams memory params)
        MultiTokenVault(params.asset)
        Timer(params.vaultStartTimestamp)
        TimelockAsyncUnlock(params.redeemNoticePeriod)
        TripleRateContext(
            params.interestRatePercentageScaled,
            params.reducedInterestRatePercentageScaled,
            currentPeriod(),
            params.frequency,
            params.tenor,
            params.asset.decimals()
        )
    {
        YIELD_STRATEGY = params.yieldStrategy;

        if (params.frequency != 360 && params.frequency != 365) {
            revert LiquidContinuousMultiTokenVault__InvalidFrequency(params.frequency);
        }
    }

    /// @dev returns
    function calcYield(uint256 principal, uint256 fromPeriod, uint256 toPeriod) public view returns (uint256 yield) {
        return YIELD_STRATEGY.calcYield(address(this), principal, fromPeriod, toPeriod);
    }

    /// @dev price is not used in Vault calculations.  however, 1 asset = 1 share, implying a price of 1
    function calcPrice(uint256 /* numPeriodsElapsed */ ) public view virtual returns (uint256 price) {
        return 1; // 1 asset = 1 share
    }

    /// @inheritdoc MultiTokenVault
    function convertToSharesForDepositPeriod(uint256 assets, uint256 /* depositPeriod */ )
        public
        view
        override
        returns (uint256 shares)
    {
        if (assets < SCALE) return 0; // no shares for fractional principal

        return assets; // 1 asset = 1 share
    }

    /// @inheritdoc MultiTokenVault
    function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod, uint256 redeemPeriod)
        public
        view
        override
        returns (uint256 assets)
    {
        if (shares < SCALE) return 0; // no assets for fractional shares

        if (redeemPeriod < depositPeriod) return 0; // trying to redeem before depositPeriod

        uint256 principal = shares; // 1 share = 1 asset.  in other words 1 share = 1 principal

        return principal + calcYield(principal, depositPeriod, redeemPeriod);
    }

    /**
     * @inheritdoc MultiTokenVault
     */
    function redeemForDepositPeriod(
        uint256 shares,
        address receiver,
        address owner,
        uint256 depositPeriod,
        uint256 redeemPeriod
    ) public virtual override returns (uint256 assets) {
        unlock(owner, depositPeriod, redeemPeriod, shares);

        return super.redeemForDepositPeriod(shares, receiver, owner, depositPeriod, redeemPeriod);
    }

    function redeemPrincipal(
        address receiver,
        address tokenOwner,
        uint256 depositPeriod,
        uint256 unlockPeriod,
        uint256 principal
    ) public {
        redeemForDepositPeriod(principal, receiver, tokenOwner, depositPeriod, unlockPeriod);

        // TODO - emit redeem redeem principal
    }

    function redeemYieldOnly(
        address receiver,
        address tokenOwner,
        uint256 depositPeriod,
        uint256 unlockPeriod,
        uint256 principal
    ) public nonReentrant {
        // only unlock the yield
        uint256 yield = calcYield(principal, depositPeriod, unlockPeriod);

        unlock(tokenOwner, depositPeriod, unlockPeriod, yield);

        // TODO - check the rights here - users shouldn't be able to mint
        // move the lock by burning and minting/locking in a new period
        _burn(tokenOwner, depositPeriod, principal);
        _mint(tokenOwner, currentPeriod(), principal, "");

        assetIERC20().safeTransfer(receiver, yield);

        // TODO - emit redeem redeem yield event
    }

    /// @notice Locks `amount` of tokens for `account` at the given `depositPeriod`.
    function lock(address account, uint256 depositPeriod, uint256 amount) public {
        _depositForDepositPeriod(amount, account, depositPeriod);
    }

    /// @notice Returns the amount of tokens locked for `account` at the given `depositPeriod`.
    function lockedAmount(address account, uint256 depositPeriod)
        public
        view
        override
        returns (uint256 lockedAmount_)
    {
        return balanceOf(account, depositPeriod);
    }

    // TODO - need to decide does unlock call redeem or vice-versa ?
    function _updateLockAfterUnlock(address, /* account */ uint256, /* depositPeriod */ uint256 amount)
        internal
        virtual
        override
    // solhint-disable-next-line no-empty-blocks
    { }

    /// @inheritdoc TimelockAsyncUnlock
    function currentPeriod() public view override returns (uint256 currentPeriod_) {
        return currentPeriodsElapsed(); // vault is 0 based. so currentPeriodsElapsed() = currentPeriod() - 0
    }

    /// @inheritdoc MultiTokenVault
    function currentPeriodsElapsed() public view override returns (uint256 numPeriodsElapsed_) {
        return Timer.elapsed24Hours(); // vault is 0 based. so currentPeriodsElapsed() = currentPeriod() - 0
    }

    /**
     * @inheritdoc TripleRateContext
     */
    // NOTE (JL,2024-09-30): Add Access Control modifier for Operator(?)
    function setReducedRateAt(uint256 tenorPeriod_, uint256 reducedRateScaled_) public override {
        super.setReducedRateAt(tenorPeriod_, reducedRateScaled_);
    }

    /**
     * @notice Sets the `reducedRateScaled_` against the Current Period.
     * @dev Convenience method for setting the Reduced Rate agains the current Tenor Period.
     *  Reverts with [TripleRateContext_PeriodRegressionNotAllowed] if current Tenor Period is before the
     *  stored current Tenor Period (the setting).  Emits [CurrentTenorPeriodAndRateChanged] upon mutation.
     *
     * @param reducedRateScaled_ The [uint256] Reduced Rate scaled percentage value.
     */
    // NOTE (JL,2024-09-30): Add Access Control modifier for Operator(?)
    function setReducedRateAtCurrent(uint256 reducedRateScaled_) public {
        super.setReducedRateAt(currentPeriod(), reducedRateScaled_);
    }
}
