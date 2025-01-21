// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IYieldStrategy } from "@credbull/yield/strategy/IYieldStrategy.sol";
import { Timer } from "@credbull/timelock/Timer.sol";

import { IERC6372 } from "@openzeppelin/contracts/interfaces/IERC6372.sol";
import { ERC4626Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { AccessControlEnumerableUpgradeable } from
    "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title LiquidContinuousMultiTokenVault
 * Vault with the following properties:
 * - Liquid - short-term time horizon
 *
 */
contract PureStone is
    Initializable,
    UUPSUpgradeable,
    ERC4626Upgradeable,
    // TimelockAsyncUnlock, // TODO - add back
    // CalcInterestMetadata, // TODO - add in
    AccessControlEnumerableUpgradeable,
    PausableUpgradeable,
    IERC6372
{
    struct VaultAuth {
        address owner;
        address operator;
        address upgrader;
        address assetManager;
    }

    struct VaultParams {
        VaultAuth vaultAuth;
        IYieldStrategy yieldStrategy;
        uint256 vaultStartTimestamp;
    }

    IYieldStrategy public _yieldStrategy;
    uint256 public _vaultStartTimestamp;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant ASSET_MANAGER_ROLE = keccak256("ASSET_MANAGER_ROLE");

    error LiquidContinuousMultiTokenVault__InvalidAuthAddress(string authName, address authAddress);

    constructor() {
        _disableInitializers();
    }

    function initialize(VaultParams memory vaultParams) public initializer {
        __UUPSUpgradeable_init();
        __AccessControl_init();
        // __CalcInterestMetadata_init(vaultParams.contextParams.) // TOOD - add in
        // __TimelockAsyncUnlock_init(vaultParams.redeemNoticePeriod); // TOOD - add in

        _initRole("owner", DEFAULT_ADMIN_ROLE, vaultParams.vaultAuth.owner);
        _initRole("operator", OPERATOR_ROLE, vaultParams.vaultAuth.operator);
        _initRole("upgrader", UPGRADER_ROLE, vaultParams.vaultAuth.upgrader);
        _initRole("assetManager", ASSET_MANAGER_ROLE, vaultParams.vaultAuth.assetManager);

        _yieldStrategy = vaultParams.yieldStrategy;
        _vaultStartTimestamp = vaultParams.vaultStartTimestamp;
    }

    function _initRole(string memory roleName, bytes32 role, address account) private {
        if (account == address(0)) {
            revert LiquidContinuousMultiTokenVault__InvalidAuthAddress(roleName, account);
        }

        _grantRole(role, account);
    }

    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal view override onlyRole(UPGRADER_ROLE) { }

    // ===================== ERC4626 =====================

    /**
     * @dev Internal conversion function (from assets to shares) with support for rounding direction.
     */
    function _convertToShares(uint256 assets, Math.Rounding /* rounding */ )
        internal
        view
        virtual
        override
        returns (uint256)
    {
        return assets;
    }

    /**
     * @dev Internal conversion function (from shares to assets) with support for rounding direction.
     */
    function _convertToAssets(uint256 shares, Math.Rounding /* rounding */ )
        internal
        view
        virtual
        override
        returns (uint256)
    {
        return shares; // assets = shares on deposit
    }

    // ===================== ERC20 =====================

    function _update(address from, address to, uint256 value) internal virtual override whenNotPaused {
        super._update(from, to, value);
    }

    // ===================== Yield / YieldStrategy =====================

    /// @dev set the YieldStrategy
    function setYieldStrategy(IYieldStrategy yieldStrategy) public onlyRole(OPERATOR_ROLE) {
        _yieldStrategy = yieldStrategy;
    }

    //    /// @dev yield accrues up to the `requestRedeemPeriod` (as opposed to the `redeemPeriod`)
    //    function calcYield(uint256 principal, uint256 depositPeriod, uint256 redeemPeriod)
    //        public
    //        view
    //        returns (uint256 yield)
    //    {
    //        uint256 requestRedeemPeriod = redeemPeriod > noticePeriod() ? redeemPeriod - noticePeriod() : 0;
    //
    //        if (requestRedeemPeriod <= depositPeriod) return 0; // no yield when deposit and requestRedeems are the same period
    //
    //        return _yieldStrategy.calcYield(address(this), principal, depositPeriod, requestRedeemPeriod);
    //    }

    /// @dev price is not used in Vault calculations.  however, 1 asset = 1 share, implying a price of 1
    function calcPrice(uint256 /* numPeriodsElapsed */ ) public view virtual returns (uint256 price) {
        return 1; // 1 asset = 1 share
    }

    // ===================== TimelockAsyncUnlock =====================

    // ===================== TripleRateContext =====================

    // ===================== Timer / IERC6372 Clock =====================

    /// @dev set the vault start timestamp
    function setVaultStartTimestamp(uint256 vaultStartTimestamp) public onlyRole(OPERATOR_ROLE) {
        _vaultStartTimestamp = vaultStartTimestamp;
    }

    //    /// @inheritdoc MultiTokenVault
    //    /// @dev vault is 0 based. so currentPeriodsElapsed() = currentPeriod() - 0
    //    function currentPeriodsElapsed() public view override returns (uint256 numPeriodsElapsed_) {
    //        return Timer.elapsed24Hours(_vaultStartTimestamp);
    //    }
    //
    //    /// @inheritdoc TimelockAsyncUnlock
    //    /// @dev vault is 0 based. so currentPeriodsElapsed() = currentPeriod() - 0
    //    function currentPeriod() public view override returns (uint256 currentPeriod_) {
    //        return currentPeriodsElapsed();
    //    }

    /// @inheritdoc IERC6372
    function clock() public view returns (uint48 clock_) {
        return Timer.clock();
    }

    /// @inheritdoc IERC6372
    function CLOCK_MODE() public pure returns (string memory) {
        return Timer.CLOCK_MODE();
    }

    // ===================== Utility =====================

    function pause() public onlyRole(OPERATOR_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(OPERATOR_ROLE) {
        _unpause();
    }

    function getVersion() public pure returns (uint256 version) {
        return 2;
    }
}
