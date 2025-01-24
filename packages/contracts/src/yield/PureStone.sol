// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IVault } from "@credbull/token/ERC4626/IVault.sol";
import { IYieldStrategy } from "@credbull/yield/strategy/IYieldStrategy.sol";
import { Timer } from "@credbull/timelock/Timer.sol";
import { CalcInterestMetadata } from "@credbull/yield/CalcInterestMetadata.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { ERC4626Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { ERC1155Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import { ERC1155SupplyUpgradeable } from
    "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import { TimelockIERC1155 } from "@credbull/timelock/TimelockIERC1155.t.sol";

import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { AccessControlEnumerableUpgradeable } from
    "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title PureStone
 * Vault with the following properties:
 * - Liquid - short-term time horizon
 * TODO - take care for deposits held longer than 1 tenor.  roll-over or grant more shares.
 */
contract PureStone is
    Initializable,
    UUPSUpgradeable,
    CalcInterestMetadata,
    ERC4626Upgradeable,
    IVault,
    AccessControlEnumerableUpgradeable,
    TimelockIERC1155
{
    IYieldStrategy public _yieldStrategy;
    uint256 public _vaultStartTimestamp;
    uint256 public _tenor;

    struct PureStoneParams {
        string name;
        string symbol;
        IERC20Metadata asset;
        IYieldStrategy yieldStrategy;
        uint256 vaultStartTimestamp;
        uint256 ratePercentageScaled;
        uint256 frequency;
        uint256 tenor;
    }

    error PureStone__InvalidRedeemForDepositPeriod(
        address caller, address owner, uint256 depositPeriod, uint256 redeemPeriod
    );

    error PureStone__WithdrawNotSupported(address caller, address owner);

    constructor() {
        _disableInitializers();
    }

    function initialize(PureStoneParams memory params) public initializer {
        __UUPSUpgradeable_init();
        __AccessControl_init();
        __ERC20_init(params.name, params.symbol);
        __ERC4626_init(params.asset);
        __TimelockIERC1155_init();
        __CalcInterestMetadata_init(params.ratePercentageScaled, params.frequency, params.asset.decimals());
        _yieldStrategy = params.yieldStrategy;
        _vaultStartTimestamp = params.vaultStartTimestamp;
        _tenor = params.tenor;
    }

    // TODO - put back access control check
    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal view virtual override { } // onlyRole(UPGRADER_ROLE) { }

    /// @inheritdoc ERC4626Upgradeable
    function asset() public view virtual override(ERC4626Upgradeable, IVault) returns (address asset_) {
        return ERC4626Upgradeable.asset();
    }

    /// @inheritdoc ERC4626Upgradeable
    function convertToShares(uint256 assets)
        public
        view
        virtual
        override(ERC4626Upgradeable, IVault)
        returns (uint256 shares)
    {
        return ERC4626Upgradeable.convertToShares(assets);
    }

    // ===================== Deposit =====================

    /// @inheritdoc ERC4626Upgradeable
    function deposit(uint256 assets, address receiver)
        public
        virtual
        override(ERC4626Upgradeable, IVault)
        returns (uint256 shares_)
    {
        uint256 shares = ERC4626Upgradeable.deposit(assets, receiver);

        // lock the shares after depositing
        _lockInternal(receiver, currentPeriod() + lockDuration(), shares);

        return shares;
    }

    // ===================== Redeem/Withdraw =====================

    /// @inheritdoc IVault
    // TODO - restrict this to only owner.  callers should just use redeem()
    function redeemForDepositPeriod(uint256 shares, address receiver, address owner, uint256 depositPeriod)
        external
        returns (uint256 assets)
    {
        uint256 currentPeriod_ = currentPeriod();

        if (currentPeriod_ != depositPeriod + lockDuration()) {
            revert PureStone__InvalidRedeemForDepositPeriod(_msgSender(), owner, depositPeriod, currentPeriod_);
        }

        return redeem(shares, receiver, owner);
    }

    /// @inheritdoc ERC4626Upgradeable
    function redeem(uint256 shares, address receiver, address owner)
        public
        virtual
        override
        returns (uint256 assets_)
    {
        // unlock the shares before redeeming
        _unlockInternal(owner, currentPeriod(), shares);

        return ERC4626Upgradeable.redeem(shares, receiver, owner);
    }

    // ===================== Internal Conversions =====================

    /// @inheritdoc ERC4626Upgradeable
    function _convertToShares(uint256 assets, Math.Rounding /* rounding */ )
        internal
        view
        virtual
        override
        returns (uint256 shares)
    {
        return assets; // 1 asset = 1 share
    }

    /// @inheritdoc ERC4626Upgradeable
    function _convertToAssets(uint256 shares, Math.Rounding /* rounding */ )
        internal
        view
        virtual
        override
        returns (uint256 assets)
    {
        uint256 _principal = shares; // 1 asset = 1 share

        return _principal + _calcFixedYield(_principal);
    }

    // ===================== IYield =====================

    function _calcFixedYield(uint256 principal) public view returns (uint256 yield) {
        return _yieldStrategy.calcYield(address(this), principal, 0, _tenor);
    }

    // ===================== Timelock =====================

    /// @inheritdoc IVault
    function sharesAtPeriod(address owner, uint256 depositPeriod) external view returns (uint256 shares) {
        return ERC1155Upgradeable.balanceOf(owner, depositPeriod + lockDuration());
    }

    function lockDuration() public view virtual override returns (uint256 lockDuration_) {
        return _tenor;
    }

    // ===================== Timer / IERC6372 Clock =====================

    /// @inheritdoc IVault
    function currentPeriodsElapsed() public view virtual override returns (uint256 currentPeriodsElapsed_) {
        return Timer.elapsed24Hours(_vaultStartTimestamp);
    }

    /// @inheritdoc TimelockIERC1155
    function currentPeriod() public view virtual override returns (uint256 currentPeriod_) {
        return currentPeriodsElapsed();
    }

    // ===================== Utility =====================

    function totalSupply()
        public
        view
        virtual
        override(ERC20Upgradeable, IERC20, ERC1155SupplyUpgradeable)
        returns (uint256)
    {
        return ERC20Upgradeable.totalSupply(); // uses ERC4626 - the official token
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerableUpgradeable, ERC1155Upgradeable)
        returns (bool)
    {
        return interfaceId == type(IVault).interfaceId || ERC1155Upgradeable.supportsInterface(interfaceId);
    }
}
