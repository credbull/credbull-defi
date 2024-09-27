// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { CalcInterestMetadata } from "@credbull/yield/CalcInterestMetadata.sol";
import { IYieldStrategy } from "@credbull/yield/strategy/IYieldStrategy.sol";
import { MultiTokenVault } from "@credbull/token/ERC1155/MultiTokenVault.sol";
import { TimelockAsyncUnlock } from "@credbull/timelock/TimelockAsyncUnlock.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title LiquidContinuousVault
 * MultiTokenVault with the following properties:
 * - Liquid - short-term time horizon
 * - Continuous - ongoing deposits and redeems without a maturity
 * - Multiple rates - full rate on deposits held "tenor" days, reduced rates for days 1-29
 * - Redeem with Notice - two step redeem process: request to redeem and then redeem after notice period
 */
contract LiquidContinuousVault is MultiTokenVault, TimelockAsyncUnlock, CalcInterestMetadata {
    using Math for uint256;

    IYieldStrategy public immutable YIELD_STRATEGY; // TODO lucasia - confirm if immutable or not
    uint256 internal _currentTimePeriodsElapsed; // TODO - replace period state with Timer implementation

    struct LiquidContinuousVaultParams {
        IERC20Metadata asset;
        IYieldStrategy yieldStrategy;
        uint256 redeemNoticePeriod;
        uint256 interestRatePercentageScaled;
        uint256 frequency; // MUST be a daily frequency, either 360 or 365
        uint256 tenor;
    }

    constructor(LiquidContinuousVaultParams memory params)
        MultiTokenVault(params.asset)
        TimelockAsyncUnlock(params.redeemNoticePeriod)
        CalcInterestMetadata(params.interestRatePercentageScaled, params.frequency, params.asset.decimals())
    {
        YIELD_STRATEGY = params.yieldStrategy;

        // TODO - revert if not a daily frequency of 360 or 365
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
        //unlock(owner, depositPeriod, shares); // TODO - add unlock here

        return super.redeemForDepositPeriod(shares, receiver, owner, depositPeriod, redeemPeriod);
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

    function currentPeriod() public view override returns (uint256 currentPeriod_) {
        return currentTimePeriodsElapsed();
    }

    /// @inheritdoc MultiTokenVault
    function currentTimePeriodsElapsed() public view override returns (uint256) {
        return _currentTimePeriodsElapsed; // TODO - replace period state with Timer implementation
    }

    function setCurrentTimePeriodsElapsed(uint256 currentTimePeriodsElapsed_) public {
        _currentTimePeriodsElapsed = currentTimePeriodsElapsed_; // TODO - replace period state with Timer implementation
    }
}
