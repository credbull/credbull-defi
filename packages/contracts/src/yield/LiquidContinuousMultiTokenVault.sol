// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { MultiTokenVault } from "@credbull/token/ERC1155/MultiTokenVault.sol";
import { IRedeemOptimizer } from "@credbull/token/ERC1155/IRedeemOptimizer.sol";
import { IComponentToken } from "@credbull/token/component/IComponentToken.sol";
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
    IComponentToken,
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
        // IRedeemOptimizer redeemOptimizer;   // TODO - add in the redeemOptimizer
        uint256 vaultStartTimestamp;
        uint256 redeemNoticePeriod;
        TripleRateContext.ContextParams contextParams;
    }

    IYieldStrategy public yieldStrategy;
    IRedeemOptimizer public redeemOptimizer;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    error LiquidContinuousMultiTokenVault__InvalidFrequency(uint256 frequency);
    error LiquidContinuousMultiTokenVault__InvalidOwnerAddress(address ownerAddress);
    error LiquidContinuousMultiTokenVault__InvalidOperatorAddress(address ownerAddress);
    error LiquidContinuousMultiTokenVault__AmountMismatch(uint256 amount1, uint256 amount2);

    function initialize(VaultParams memory vaultParams) public initializer {
        __UUPSUpgradeable_init();
        __AccessControl_init();
        __MultiTokenVault_init(vaultParams.asset);
        __TimelockAsyncUnlock_init(vaultParams.redeemNoticePeriod);
        __TripleRateContext_init(vaultParams.contextParams);
        __Timer_init(vaultParams.vaultStartTimestamp);

        if (vaultParams.contractOwner == address(0)) {
            revert LiquidContinuousMultiTokenVault__InvalidOwnerAddress(vaultParams.contractOwner);
        }

        if (vaultParams.contractOperator == address(0)) {
            revert LiquidContinuousMultiTokenVault__InvalidOperatorAddress(vaultParams.contractOwner);
        }

        _grantRole(DEFAULT_ADMIN_ROLE, vaultParams.contractOwner);
        _grantRole(OPERATOR_ROLE, vaultParams.contractOperator);
        _grantRole(UPGRADER_ROLE, vaultParams.contractOperator);

        yieldStrategy = vaultParams.yieldStrategy;

        if (vaultParams.contextParams.frequency != 360 && vaultParams.contextParams.frequency != 365) {
            revert LiquidContinuousMultiTokenVault__InvalidFrequency(vaultParams.contextParams.frequency);
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

    /// @inheritdoc IComponentToken
    /// @dev - requesting to buy is not required, Users can directly executeBuy
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

    /// @inheritdoc IComponentToken
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

    /// @inheritdoc IComponentToken
    function executeBuy(
        address requestor,
        uint256, /* requestId */
        uint256 currencyTokenAmount,
        uint256 componentTokenAmount
    ) public override {
        if (currencyTokenAmount != componentTokenAmount) {
            revert LiquidContinuousMultiTokenVault__AmountMismatch(currencyTokenAmount, componentTokenAmount);
        }

        deposit(currencyTokenAmount, requestor);
    }

    /// @inheritdoc IComponentToken
    function executeSell(
        address requestor,
        uint256 requestId,
        uint256 currencyTokenAmount,
        uint256 componentTokenAmount
    ) public override {
        // TODO - verify currencyTokenAmount convertToAssets(componentTokenAmount) = currencyTokenAmount
        // TODO - verifying currencyTokeAmount figuring out the componentTokenAmount here is non-trivial.  it will span multiple periods.
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

    // ===================== Yield / YieldStrategy =====================

    /// @dev yield based on the associated yieldStrategy
    function calcYield(uint256 principal, uint256 fromPeriod, uint256 toPeriod) public view returns (uint256 yield) {
        return yieldStrategy.calcYield(address(this), principal, fromPeriod, toPeriod);
    }

    /// @dev price is not used in Vault calculations.  however, 1 asset = 1 share, implying a price of 1
    function calcPrice(uint256 /* numPeriodsElapsed */ ) public view virtual returns (uint256 price) {
        return 1; // 1 asset = 1 share
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

    // ===================== TripleRateContext =====================

    /// @inheritdoc TripleRateContext
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

    // ===================== Utility =====================

    /// @inheritdoc TimelockAsyncUnlock
    function currentPeriod() public view override returns (uint256 currentPeriod_) {
        return currentPeriodsElapsed(); // vault is 0 based. so currentPeriodsElapsed() = currentPeriod() - 0
    }

    /// @inheritdoc MultiTokenVault
    function currentPeriodsElapsed() public view override returns (uint256 numPeriodsElapsed_) {
        return elapsed24Hours(); // vault is 0 based. so currentPeriodsElapsed() = currentPeriod() - 0
    }

    function pause() public onlyRole(OPERATOR_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(OPERATOR_ROLE) {
        _unpause();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(MultiTokenVault, AccessControlUpgradeable)
        returns (bool)
    {
        return MultiTokenVault.supportsInterface(interfaceId);
    }

    function getVersion() external view returns (uint256 version) {
        return 1;
    }
}
