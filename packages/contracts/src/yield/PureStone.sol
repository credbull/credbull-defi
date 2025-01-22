// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IVault } from "@credbull/token/ERC4626/IVault.sol";

import { DiscountVault } from "@credbull/token/ERC4626/DiscountVault.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { ERC4626Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";

/**
 * @title PureStone
 * Vault with the following properties:
 * - Liquid - short-term time horizon
 *
 */
contract PureStone is DiscountVault, IVault {
    constructor() {
        _disableInitializers();
    }

    function initialize(DiscountVault.DiscountVaultParams memory params) public initializer {
        __DiscountVault_init(params);
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

    // ===================== MultiTokenVault =====================

    /// @inheritdoc ERC4626Upgradeable
    function asset() public view virtual override(ERC4626Upgradeable, IERC4626, IVault) returns (address asset_) {
        return ERC4626Upgradeable.asset();
    }

    /// @inheritdoc IVault
    // MultiToken variant MUST redeem at the given `depositPeriod`
    // Single Token variant MUST return the 'logical' shares for the period (e.g. considering locks)
    function redeemForDepositPeriod(uint256 shares, address receiver, address owner, uint256 /* depositPeriod */ )
        external
        returns (uint256 assets)
    {
        return redeem(shares, receiver, owner); // TODO - check timelock for shares at deposit period
    }

    // MultiToken variant MUST return the balanceOf for the `depositPeriod`
    // Single Token variant MUST return the 'logical' shares for the period (e.g. considering locks)
    function sharesAtPeriod(address owner, uint256 /* depositPeriod */ ) external view returns (uint256 shares) {
        return balanceOf(owner); // TODO - check timelock for shares at deposit period
    }

    /// @inheritdoc ERC4626Upgradeable
    function deposit(uint256 assets, address receiver)
        public
        virtual
        override(ERC4626Upgradeable, IERC4626, IVault)
        returns (uint256 shares)
    {
        // TODO - confirm if we also deposit into multi token - maybe we can just mint instead
        // MultiTokenVault._depositForDepositPeriod(assets, receiver, currentPeriodsElapsed());

        return ERC4626Upgradeable.deposit(assets, receiver);
    }

    /// minimum shares required to convert to assets and vice-versa.
    function _minConversionThreshold() internal view returns (uint256 minConversionThreshold) {
        return SCALE < 10 ? SCALE : 10;
    }

    // ===================== Timer / IERC6372 Clock =====================

    /// @inheritdoc DiscountVault
    function currentPeriodsElapsed() public view virtual override(DiscountVault, IVault) returns (uint256) {
        return DiscountVault.currentPeriodsElapsed();
    }

    // ===================== Utility =====================
}
