// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { MultiTokenVault } from "@credbull/token/ERC1155/MultiTokenVault.sol";
import { ITradeable } from "@credbull/yield/ITradeable.sol";
import { TimelockAsyncUnlock } from "@credbull/timelock/TimelockAsyncUnlock.sol";
import { TripleRateContext } from "@credbull/yield/context/TripleRateContext.sol";
import { IYieldStrategy } from "@credbull/yield/strategy/IYieldStrategy.sol";
import { Timer } from "@credbull/timelock/Timer.sol";

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { TripleRateContext } from "@credbull/yield/context/TripleRateContext.sol";

/**
 * @title LiquidContinuousMultiTokenVault
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
contract LiquidContinuousMultiTokenVault is
    Initializable,
    UUPSUpgradeable,
    MultiTokenVault,
    ITradeable,
    TimelockAsyncUnlock,
    Timer,
    TripleRateContext,
    AccessControlUpgradeable
{
    using SafeERC20 for IERC20;

    struct VaultParams {
        address contractOwner;
        address contractOperator;
        IERC20Metadata asset;
        IYieldStrategy yieldStrategy;
        uint256 vaultStartTimestamp;
        uint256 redeemNoticePeriod;
        uint256 fullRateScaled;
        uint256 reducedRateScaled;
        uint256 frequency; // MUST be a daily frequency, either 360 or 365
        uint256 tenor;
    }

    IYieldStrategy public YIELD_STRATEGY; // TODO lucasia - confirm if immutable or not

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    error LiquidContinuousMultiTokenVault__InvalidFrequency(uint256 frequency);
    error LiquidContinuousMultiTokenVault__InvalidOwnerAddress(address ownerAddress);
    error LiquidContinuousMultiTokenVault__InvalidOperatorAddress(address ownerAddress);

    function initialize(VaultParams memory params) public initializer {
        __UUPSUpgradeable_init();
        __AccessControl_init();
        __MultiTokenVault_init(params.asset);
        __TimelockAsyncUnlock_init(params.redeemNoticePeriod);
        __TripleRateContext_init(
            ContextParams({
                fullRateScaled: params.fullRateScaled,
                initialReducedRate: PeriodRate({ interestRate: params.reducedRateScaled, effectiveFromPeriod: 0 }),
                frequency: params.frequency,
                tenor: params.tenor,
                decimals: params.asset.decimals()
            })
        );
        __Timer_init(params.vaultStartTimestamp);

        if (params.contractOwner == address(0)) {
            revert LiquidContinuousMultiTokenVault__InvalidOwnerAddress(params.contractOwner);
        }

        if (params.contractOperator == address(0)) {
            revert LiquidContinuousMultiTokenVault__InvalidOperatorAddress(params.contractOwner);
        }

        _grantRole(DEFAULT_ADMIN_ROLE, params.contractOwner);
        _grantRole(OPERATOR_ROLE, params.contractOperator);
        _grantRole(UPGRADER_ROLE, params.contractOperator);

        YIELD_STRATEGY = params.yieldStrategy;

        if (params.frequency != 360 && params.frequency != 365) {
            revert LiquidContinuousMultiTokenVault__InvalidFrequency(params.frequency);
        }
    }

    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal view override onlyRole(UPGRADER_ROLE) { }
    // ===================== MultiTokenVault =====================

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

    // ===================== Buyable/Sellable =====================

    /// @inheritdoc ITradeable
    /// @dev - requesting to buy is not required, User directly executeBuy
    function requestBuy(uint256 /* currencyTokenAmount */ )
        public
        view
        virtual
        override
        onlyRole(OPERATOR_ROLE)
        returns (uint256 requestId)
    {
        return 0;
    }

    /// @inheritdoc ITradeable
    function requestSell(uint256 componentTokenAmount) public virtual override returns (uint256 requestId) {
        // TODO - need helper to find which depositPeriods we want to sell from...

        return _requestSell(componentTokenAmount, currentPeriod());
    }

    /// @notice Request to sell (redeem) `amount` of tokens at the `depositPeriod`
    /// @param amount The amount a User wants to sell (redeem).  This could be yield only, or include principal + yield.
    function _requestSell(uint256 amount, uint256 depositPeriod) internal virtual returns (uint256 requestId) {
        requestUnlock(_msgSender(), depositPeriod, _minUnlockPeriod(), amount);

        return 0; // TODO - need to add requestId to requestUnlock()
    }

    /// @inheritdoc ITradeable
    function executeBuy(
        address requestor,
        uint256, /* requestId */
        uint256 currencyTokenAmount,
        uint256 /* componentTokenAmount */
    ) public override {
        // TODO - verify currencyTokenAmount convertToShares(currencyTokenAmount) = componentTokenAmount

        deposit(currencyTokenAmount, requestor);
    }

    /// @inheritdoc ITradeable
    function executeSell(
        address requestor,
        uint256 requestId,
        uint256 currencyTokenAmount,
        uint256 componentTokenAmount
    ) public override {
        // TODO - verify currencyTokenAmount convertToAssets(componentTokenAmount) = currencyTokenAmount
        _executeSell(requestor, currentPeriod(), requestId, currencyTokenAmount, componentTokenAmount);
    }

    function _executeSell(
        address requestor,
        uint256 depositPeriod,
        uint256, /* requestId */
        uint256, /* currencyTokenAmount */
        uint256 componentTokenAmount
    ) internal {
        // TODO - verify currencyTokenAmount convertToAssets(componentTokenAmount) = currencyTokenAmount
        // TODO - need helper to find which depositPeriods we want to sell from...
        redeemForDepositPeriod(componentTokenAmount, requestor, requestor, depositPeriod, currentPeriod());
    }

    // solhint-disable-next-line
    function distributeYield(address user, uint256 amount) external { }

    /// @notice Returns the total yield generated by the contract.
    function yieldGenerated() external pure returns (uint256 yield) {
        return 0;
    }

    // ===================== Yield =====================

    /// @dev yield based on the associated yieldStrategy
    function calcYield(uint256 principal, uint256 fromPeriod, uint256 toPeriod) public view returns (uint256 yield) {
        return YIELD_STRATEGY.calcYield(address(this), principal, fromPeriod, toPeriod);
    }

    /// @dev price is not used in Vault calculations.  however, 1 asset = 1 share, implying a price of 1
    function calcPrice(uint256 /* numPeriodsElapsed */ ) public view virtual returns (uint256 price) {
        return 1; // 1 asset = 1 share
    }

    /// @notice Harvest yield for the given `principal`, but keeping the principal invested.
    function _harvestYield(address tokenOwner, uint256 depositPeriod, uint256 unlockPeriod, uint256 principal)
        internal
        nonReentrant
    {
        // only unlock the yield
        uint256 yield = calcYield(principal, depositPeriod, unlockPeriod);

        unlock(tokenOwner, depositPeriod, unlockPeriod, yield);

        // move the lock by burning and minting/locking in a new period
        _burn(tokenOwner, depositPeriod, principal);
        _mint(tokenOwner, currentPeriod(), principal, ""); // TODO confirm access.  Operators only or user allowed action?

        assetIERC20().safeTransfer(tokenOwner, yield);

        // TODO - emit redeem redeem yield event
    }

    // ===================== TimelockAsyncUnlock =====================

    /// @notice Locks `amount` of tokens for `account` at the given `depositPeriod`.
    /// @dev - users should call deposit() instead that returns shares
    function lock(address account, uint256 depositPeriod, uint256 amount) public onlyRole(OPERATOR_ROLE) {
        _depositForDepositPeriod(amount, account, depositPeriod);
    }

    /// @inheritdoc TimelockAsyncUnlock
    function lockedAmount(address account, uint256 depositPeriod)
        public
        view
        override
        returns (uint256 lockedAmount_)
    {
        return balanceOf(account, depositPeriod);
    }

    // ===================== ERC1155Pausable =====================

    function pause() public onlyRole(OPERATOR_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(OPERATOR_ROLE) {
        _unpause();
    }

    // ===================== Utility =====================

    /// @inheritdoc TimelockAsyncUnlock
    function currentPeriod() public view override returns (uint256 currentPeriod_) {
        return currentPeriodsElapsed(); // vault is 0 based. so currentPeriodsElapsed() = currentPeriod() - 0
    }

    /// @inheritdoc MultiTokenVault
    function currentPeriodsElapsed() public view override returns (uint256 numPeriodsElapsed_) {
        return elapsed24Hours(); // vault is 0 based. so currentPeriodsElapsed() = currentPeriod() - 0
    }

    /// @inheritdoc MultiTokenVault
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(MultiTokenVault, AccessControlUpgradeable)
        returns (bool)
    {
        return MultiTokenVault.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc TripleRateContext
     */
    function setReducedRate(uint256 reducedRateScaled_, uint256 effectiveFromPeriod_)
        public
        override
        onlyRole(OPERATOR_ROLE)
    {
        super.setReducedRate(effectiveFromPeriod_, reducedRateScaled_);
    }

    /**
     * @notice Sets the `reducedRateScaled_` against the Current Period.
     * @dev Convenience method for setting the Reduced Rate agains the current Period.
     *  Reverts with [TripleRateContext_PeriodRegressionNotAllowed] if current Period is before the
     *  stored current Period (the setting).  Emits [CurrentPeriodRateChanged] upon mutation.
     *
     * @param reducedRateScaled_ The scaled percentage 'reduced' Interest Rate.
     */
    function setReducedRateAtCurrent(uint256 reducedRateScaled_) public onlyRole(OPERATOR_ROLE) {
        super.setReducedRate(currentPeriod(), reducedRateScaled_);
    }
}
