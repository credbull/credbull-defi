// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IVault } from "@credbull/token/ERC4626/IVault.sol";

import { DiscountVault } from "@credbull/token/ERC4626/DiscountVault.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { ERC4626Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { ERC1155Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import { ERC1155SupplyUpgradeable } from
    "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import { TimelockIERC1155 } from "@credbull/timelock/TimelockIERC1155.t.sol";

/**
 * @title PureStone
 * Vault with the following properties:
 * - Liquid - short-term time horizon
 * TODO - what about deposits held longer than 1 tenor?  should we roll-over or grant more shares ?
 */
contract PureStone is DiscountVault, IVault, TimelockIERC1155 {
    constructor() {
        _disableInitializers();
    }

    function initialize(DiscountVault.DiscountVaultParams memory params) public initializer {
        __DiscountVault_init(params);
        __TimelockIERC1155_init();
    }

    // TODO - confirm which version here we want to use
    /// @inheritdoc ERC4626Upgradeable
    function convertToShares(uint256 assets)
        public
        view
        virtual
        override(ERC4626Upgradeable, IERC4626, IVault)
        returns (uint256 shares)
    {
        return ERC4626Upgradeable.convertToShares(assets);
    }

    /// @inheritdoc ERC4626Upgradeable
    // TODO - use the locks here to give the true convertToAssets
    function previewDeposit(uint256 shares)
        public
        view
        virtual
        override(ERC4626Upgradeable, IERC4626)
        returns (uint256 assets)
    {
        // TODO - use the locks for the actual depositPeriods and prices
        return super.previewDeposit(shares);
    }

    // ===================== MultiTokenVault =====================

    /// @inheritdoc ERC4626Upgradeable
    function asset() public view virtual override(ERC4626Upgradeable, IERC4626, IVault) returns (address asset_) {
        return ERC4626Upgradeable.asset();
    }

    /// @inheritdoc IVault
    // MultiToken variant MUST redeem at the given `depositPeriod`
    // Single Token variant MUST redeem the 'logical' shares for the period (e.g. considering locks)
    function redeemForDepositPeriod(uint256 shares, address receiver, address owner, uint256 /* depositPeriod */ )
        external
        returns (uint256 assets)
    {
        return redeem(shares, receiver, owner);
    }

    // MultiToken variant MUST return the balanceOf for the `depositPeriod`
    // Single Token variant MUST return the 'logical' shares for the period (e.g. considering locks)
    function sharesAtPeriod(address owner, uint256 depositPeriod) external view returns (uint256 shares) {
        return ERC1155Upgradeable.balanceOf(owner, depositPeriod + lockDuration());
    }

    /// @inheritdoc ERC4626Upgradeable
    function deposit(uint256 assets, address receiver)
        public
        virtual
        override(ERC4626Upgradeable, IERC4626, IVault)
        returns (uint256 shares_)
    {
        uint256 shares = ERC4626Upgradeable.deposit(assets, receiver);

        // lock the shares after depositing
        _lockInternal(receiver, lockDuration(), shares);

        return shares;
    }

    /// @inheritdoc ERC4626Upgradeable
    function redeem(uint256 shares, address receiver, address owner)
        public
        virtual
        override(ERC4626Upgradeable, IERC4626)
        returns (uint256 assets_)
    {
        // unlock the shares before redeeming
        _unlockInternal(owner, currentPeriod(), shares);

        return ERC4626Upgradeable.redeem(shares, receiver, owner);
    }

    /// minimum shares required to convert to assets and vice-versa.
    function _minConversionThreshold() internal view returns (uint256 minConversionThreshold) {
        return SCALE < 10 ? SCALE : 10;
    }

    // ===================== Timelock =====================

    function lockDuration() public view virtual override returns (uint256 lockDuration_) {
        return _tenor;
    }

    // ===================== Timer / IERC6372 Clock =====================

    /// @inheritdoc DiscountVault
    function currentPeriodsElapsed() public view virtual override(DiscountVault, IVault) returns (uint256) {
        return DiscountVault.currentPeriodsElapsed();
    }

    function currentPeriod() public view virtual override returns (uint256 currentPeriod_) {
        return currentPeriodsElapsed();
    }

    // ===================== Utility =====================

    // uses  ERC4626 - the official token
    function totalSupply()
        public
        view
        virtual
        override(ERC20Upgradeable, IERC20, ERC1155SupplyUpgradeable)
        returns (uint256)
    {
        return ERC20Upgradeable.totalSupply();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(DiscountVault, ERC1155Upgradeable)
        returns (bool)
    {
        return DiscountVault.supportsInterface(interfaceId) || ERC1155Upgradeable.supportsInterface(interfaceId);
    }
}
