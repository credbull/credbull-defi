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
import { IERC6372 } from "@openzeppelin/contracts/interfaces/IERC6372.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { AccessControlEnumerableUpgradeable } from
    "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";

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
    TripleRateContext,
    AccessControlEnumerableUpgradeable,
    IERC6372
{
    using SafeERC20 for IERC20;

    struct VaultAuth {
        address owner;
        address operator;
        address upgrader;
        address assetManager;
    }

    struct VaultParams {
        VaultAuth vaultAuth;
        IERC20Metadata asset;
        IYieldStrategy yieldStrategy;
        IRedeemOptimizer redeemOptimizer;
        uint256 vaultStartTimestamp;
        uint256 redeemNoticePeriod;
        TripleRateContext.ContextParams contextParams;
    }

    IYieldStrategy public _yieldStrategy;
    IRedeemOptimizer public _redeemOptimizer;
    uint256 public _vaultStartTimestamp;

    uint256 private constant ZERO_REQUEST_ID = 0;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant ASSET_MANAGER_ROLE = keccak256("ASSET_MANAGER_ROLE");

    error LiquidContinuousMultiTokenVault__InvalidFrequency(uint256 frequency);
    error LiquidContinuousMultiTokenVault__InvalidAuthAddress(string authName, address authAddress);
    error LiquidContinuousMultiTokenVault__ControllerNotSender(address sender, address controller);
    error LiquidContinuousMultiTokenVault__UnAuthorized(address sender, address authorizedOwner);
    error LiquidContinuousMultiTokenVault__AmountMismatch(uint256 amount1, uint256 amount2);
    error LiquidContinuousMultiTokenVault__UnlockPeriodMismatch(uint256 unlockPeriod1, uint256 unlockPeriod2);
    error LiquidContinuousMultiTokenVault__InvalidComponentTokenAmount(
        uint256 componentTokenAmount, uint256 unlockRequestedAmount
    );

    constructor() {
        _disableInitializers();
    }

    function initialize(VaultParams memory vaultParams) public initializer {
        __UUPSUpgradeable_init();
        __AccessControl_init();
        __MultiTokenVault_init(vaultParams.asset);
        __TimelockAsyncUnlock_init(vaultParams.redeemNoticePeriod);
        __TripleRateContext_init(vaultParams.contextParams);

        _initRole("owner", DEFAULT_ADMIN_ROLE, vaultParams.vaultAuth.owner);
        _initRole("operator", OPERATOR_ROLE, vaultParams.vaultAuth.operator);
        _initRole("upgrader", UPGRADER_ROLE, vaultParams.vaultAuth.upgrader);
        _initRole("assetManager", ASSET_MANAGER_ROLE, vaultParams.vaultAuth.assetManager);

        _yieldStrategy = vaultParams.yieldStrategy;
        _redeemOptimizer = vaultParams.redeemOptimizer;
        _vaultStartTimestamp = vaultParams.vaultStartTimestamp;

        if (vaultParams.contextParams.frequency != 360 && vaultParams.contextParams.frequency != 365) {
            revert LiquidContinuousMultiTokenVault__InvalidFrequency(vaultParams.contextParams.frequency);
        }
    }

    function _initRole(string memory roleName, bytes32 role, address account) private {
        if (account == address(0)) {
            revert LiquidContinuousMultiTokenVault__InvalidAuthAddress(roleName, account);
        }

        _grantRole(role, account);
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
        _unlock(owner, depositPeriod, redeemPeriod, shares);

        return _redeemForDepositPeriodAfterUnlock(shares, receiver, owner, depositPeriod, redeemPeriod);
    }

    /// redeemForDepositPeriod after unlocking.  calling function MUST call unlock() prior.
    function _redeemForDepositPeriodAfterUnlock(
        uint256 shares,
        address receiver,
        address owner,
        uint256 depositPeriod,
        uint256 redeemPeriod
    ) internal virtual returns (uint256 assets) {
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

    // ===================== IComponent =====================
    // User Functions

    /**
     * @notice Transfer assets from the owner into the vault and submit a request to buy shares
     * @param assets Amount of `asset` to deposit
     * @param owner Source of the assets to deposit
     * @return requestId_ Discriminator between non-fungible requests
     */
    function requestDeposit(uint256 assets, address controller, address owner)
        public
        onlyAuthorized(owner)
        onlyController(controller)
        returns (uint256 requestId_)
    {
        uint256 requestId = ZERO_REQUEST_ID; // requests and requestIds not used in buys.

        deposit(assets, owner, controller);
        emit DepositRequest(controller, owner, requestId, _msgSender(), assets);
        return requestId;
    }

    /**
     * @notice Fulfill a request to buy shares by minting shares to the receiver
     * @param assets Amount of `asset` that was deposited by `requestDeposit`
     * @param receiver Address to receive the shares
     */
    function deposit(uint256 assets, address receiver, address controller)
        public
        onlyController(controller)
        returns (uint256 shares_)
    {
        uint256 shares = deposit(assets, receiver);
        emit Deposit(controller, receiver, assets, shares);
        return shares;
    }

    /**
     * @notice Transfer shares from the owner into the vault and submit a request to redeem assets
     * @param shares Amount of shares to redeem
     * @param owner Source of the shares to redeem
     * @return requestId_ Discriminator between non-fungible requests
     */
    function requestRedeem(uint256 shares, address controller, address owner)
        public
        onlyAuthorized(owner)
        onlyController(controller)
        returns (uint256 requestId_)
    {
        // using optimize() variant in case "shares" represents the IComponent "principal + yield" which is our "assets".
        (uint256[] memory depositPeriods, uint256[] memory sharesAtPeriods) =
            _redeemOptimizer.optimize(this, owner, shares, shares, minUnlockPeriod());

        uint256 requestId = requestUnlock(owner, depositPeriods, sharesAtPeriods);
        emit RedeemRequest(controller, owner, requestId, _msgSender(), shares);
        return requestId;
    }

    /**
     * @notice Fulfill a request to redeem assets by transferring assets to the receiver
     * @param shares Amount of shares that was redeemed by `requestRedeem`
     * @param receiver Address to receive the assets
     * @dev controller will only have tokens to redeem if they are also the owner
     */
    function redeem(uint256 shares, address receiver, address controller)
        public
        onlyController(controller)
        returns (uint256 assets)
    {
        uint256 requestId = currentPeriod(); // requestId = redeemPeriod, and redeem can only be called  where redeemPeriod = currentPeriod()

        uint256 unlockRequestedAmount = unlockRequestAmount(controller, requestId);
        if (shares != unlockRequestedAmount) {
            revert LiquidContinuousMultiTokenVault__InvalidComponentTokenAmount(shares, unlockRequestedAmount);
        }

        (uint256[] memory depositPeriods, uint256[] memory sharesAtPeriods) = unlock(controller, requestId); // unlockPeriod = redeemPeriod

        uint256 totalAssetsRedeemed = 0;

        for (uint256 i = 0; i < depositPeriods.length; ++i) {
            totalAssetsRedeemed += _redeemForDepositPeriodAfterUnlock(
                sharesAtPeriods[i], receiver, controller, depositPeriods[i], requestId
            );
        }
        emit Withdraw(_msgSender(), receiver, controller, totalAssetsRedeemed, shares);
        return totalAssetsRedeemed;
    }

    // Getter View Functions

    /// @notice Address of the `asset` token
    function asset() public view override(IComponentToken, MultiTokenVault) returns (address assetTokenAddress) {
        return MultiTokenVault.asset();
    }

    /// @notice Total amount of `asset` held in the vault
    // @dev - this is a heavy operation as the period of the vault increases
    function totalAssets() public view returns (uint256 totalManagedAssets) {
        uint256 totalAssets_ = 0;
        uint256 currentPeriod_ = currentPeriod();

        for (uint256 depositPeriod = 0; depositPeriod <= currentPeriod_; ++depositPeriod) {
            totalAssets_ += convertToAssetsForDepositPeriod(totalSupply(depositPeriod), depositPeriod);
        }

        return totalAssets_;
    }

    /**
     * @notice Equivalent amount of shares for the given amount of assets
     * @param assets Amount of `asset` to convert
     * @return shares Amount of shares that would be received in exchange
     * @dev - used for deposits, assumes depositPeriod == currentPeriod()
     */
    function convertToShares(uint256 assets)
        public
        view
        override(IComponentToken, MultiTokenVault)
        returns (uint256 shares)
    {
        return MultiTokenVault.convertToShares(assets);
    }

    /**
     * @notice Equivalent amount of assets for the given amount of shares
     * @param shares Amount of shares to convert
     * @return assets_ Amount of `asset` that would be received in exchange
     * @dev - WARNING convertToAssets(shares) is User-specific as no depositPeriod is specified
     *  for User-agnostic, use convertToAssetsForDepositPeriod(shares, depositPeriod)
     */
    function convertToAssets(uint256 shares) public view returns (uint256 assets_) {
        uint256 assets = 0;

        (uint256[] memory depositPeriods, uint256[] memory sharesAtPeriods) =
            _redeemOptimizer.optimizeRedeemShares(this, _msgSender(), shares, minUnlockPeriod());

        for (uint256 i = 0; i < depositPeriods.length; ++i) {
            assets += convertToAssetsForDepositPeriod(sharesAtPeriods[i], depositPeriods[i]);
        }

        return assets;
    }

    /**
     * @notice Total amount of assets sent to the vault as part of pending deposit requests
     * @return assets Amount of pending deposit assets for the given requestId and controller
     * @dev - deposits can be processed immediately.  therefore nothing pending.
     */
    function pendingDepositRequest(uint256, /* requestId */ address /* controller */ )
        public
        pure
        returns (uint256 assets)
    {
        return 0;
    }

    /**
     * @notice Total amount of assets sitting in the vault as part of claimable deposit requests
     * @return assets Amount of claimable deposit assets for the given requestId and controller
     * @dev - deposits can be processed immediately.  therefore nothing to claim.
     */
    function claimableDepositRequest(uint256, /* requestId */ address /* controller */ )
        public
        pure
        returns (uint256 assets)
    {
        return 0;
    }

    /**
     * @notice Total amount of shares sent to the vault as part of pending redeem requests
     * @param requestId Discriminator between non-fungible requests
     * @return shares Amount of pending redeem shares for the given requestId and controller
     */
    function pendingRedeemRequest(uint256 requestId, address /* controller */ ) public view returns (uint256 shares) {
        return unlockRequestAmount(_msgSender(), requestId);
    }

    /**
     * @notice Total amount of assets sitting in the vault as part of claimable redeem requests
     * @param requestId Discriminator between non-fungible requests
     * @param controller Controller of the requests
     * @return shares Amount of claimable redeem shares for the given requestId and controller
     */
    function claimableRedeemRequest(uint256 requestId, address controller) public view returns (uint256 shares) {
        return (currentPeriod() == requestId) ? pendingRedeemRequest(requestId, controller) : 0;
    }

    // ===================== RedeemOptimizer =====================

    /// @dev set the IRedeemOptimizer
    function setRedeemOptimizer(IRedeemOptimizer redeemOptimizer) public onlyRole(OPERATOR_ROLE) {
        _redeemOptimizer = redeemOptimizer;
    }

    // ===================== Yield / YieldStrategy =====================

    /// @dev set the YieldStrategy
    function setYieldStrategy(IYieldStrategy yieldStrategy) public onlyRole(OPERATOR_ROLE) {
        _yieldStrategy = yieldStrategy;
    }

    /// @dev yield based on the associated yieldStrategy
    function calcYield(uint256 principal, uint256 fromPeriod, uint256 toPeriod) public view returns (uint256 yield) {
        return _yieldStrategy.calcYield(address(this), principal, fromPeriod, toPeriod);
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

    /// @inheritdoc TimelockAsyncUnlock
    function _authorizeCaller(address caller, address owner) internal virtual override {
        if (caller != owner && !isApprovedForAll(owner, caller)) {
            revert LiquidContinuousMultiTokenVault__UnAuthorized(caller, owner);
        }
    }

    // ===================== TripleRateContext =====================

    /// @inheritdoc TripleRateContext
    function setReducedRate(uint256 reducedRateScaled_, uint256 effectiveFromPeriod_)
        public
        override
        onlyRole(OPERATOR_ROLE)
    {
        super.setReducedRate(reducedRateScaled_, effectiveFromPeriod_);
    }

    /**
     * @dev Withdraws the assets from out of vault for investment, i.e. in RWA.
     * Only the Asset Manager can call this function.
     *
     * @param to The trusted address that will receive the assets, e.g. custodian
     * @param amount The amount of the ERC-20 underlying assets to be withdrawn from the vault.
     */
    function withdrawAsset(address to, uint256 amount) public onlyRole(ASSET_MANAGER_ROLE) {
        _withdrawAssest(to, amount);
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
        setReducedRate(reducedRateScaled_, currentPeriod());
    }

    // ===================== Timer / IERC6372 Clock =====================

    /// @dev set the vault start timestamp
    function setVaultStartTimestamp(uint256 vaultStartTimestamp) public onlyRole(OPERATOR_ROLE) {
        _vaultStartTimestamp = vaultStartTimestamp;
    }

    /// @inheritdoc MultiTokenVault
    /// @dev vault is 0 based. so currentPeriodsElapsed() = currentPeriod() - 0
    function currentPeriodsElapsed() public view override returns (uint256 numPeriodsElapsed_) {
        return Timer.elapsed24Hours(_vaultStartTimestamp);
    }

    /// @inheritdoc TimelockAsyncUnlock
    /// @dev vault is 0 based. so currentPeriodsElapsed() = currentPeriod() - 0
    function currentPeriod() public view override returns (uint256 currentPeriod_) {
        return currentPeriodsElapsed();
    }

    /// @inheritdoc IERC6372
    function clock() public view returns (uint48 clock_) {
        return Timer.clock();
    }

    /// @inheritdoc IERC6372
    function CLOCK_MODE() public pure returns (string memory) {
        return Timer.CLOCK_MODE();
    }

    // ===================== Utility =====================

    // @dev ensure caller is permitted to act on the owner's tokens
    modifier onlyAuthorized(address owner) {
        _authorizeCaller(msg.sender, owner);
        _;
    }

    // @dev ensure the controller is the caller
    modifier onlyController(address controller) {
        address caller = _msgSender();

        if (caller != controller) {
            revert LiquidContinuousMultiTokenVault__ControllerNotSender(caller, controller);
        }
        _;
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
        override(MultiTokenVault, AccessControlEnumerableUpgradeable, TimelockAsyncUnlock)
        returns (bool)
    {
        return TimelockAsyncUnlock.supportsInterface(interfaceId) || MultiTokenVault.supportsInterface(interfaceId);
    }

    function getVersion() public pure returns (uint256 version) {
        return 1;
    }
}
