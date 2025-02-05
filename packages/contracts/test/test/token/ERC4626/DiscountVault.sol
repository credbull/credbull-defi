// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { CalcDiscounted } from "@credbull/yield/CalcDiscounted.sol";
import { IDiscountVault } from "@test/test/token/ERC4626/IDiscountVault.sol";
import { IYieldStrategy } from "@credbull/yield/strategy/IYieldStrategy.sol";
import { Timer } from "@credbull/timelock/Timer.sol";
import { CalcInterestMetadata } from "@credbull/yield/CalcInterestMetadata.sol";

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { ERC4626Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { AccessControlEnumerableUpgradeable } from
    "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

/**
 * @title DiscountVault
 * @dev A vault that uses SimpleInterest to calculate shares per asset.
 * @notice Children MUST implement Access Control for sensitive operations (e.g. Upgrading, Asset movements)
 */
contract DiscountVault is
    Initializable,
    UUPSUpgradeable,
    IDiscountVault,
    CalcInterestMetadata,
    ERC4626Upgradeable,
    ReentrancyGuardUpgradeable,
    AccessControlEnumerableUpgradeable
{
    using Math for uint256;

    IYieldStrategy public _yieldStrategy;
    uint256 public _vaultStartTimestamp;
    uint256 public _tenor;

    struct DiscountVaultParams {
        IERC20Metadata asset;
        IYieldStrategy yieldStrategy;
        uint256 vaultStartTimestamp;
        uint256 ratePercentageScaled;
        uint256 frequency;
        uint256 tenor;
    }

    constructor() {
        _disableInitializers();
    }

    function __DiscountVault_init(DiscountVaultParams memory params) public initializer {
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __AccessControl_init();
        __ERC20_init("Simple Interest Rate Claim", "cSIR"); // TODO - parameterize these
        __ERC4626_init(params.asset);
        __CalcInterestMetadata_init(params.ratePercentageScaled, params.frequency, params.asset.decimals());

        _yieldStrategy = params.yieldStrategy;
        _vaultStartTimestamp = params.vaultStartTimestamp;
        _tenor = params.tenor;
    }

    // TODO - put back access control check
    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal view virtual override { } // onlyRole(UPGRADER_ROLE) { }

    /// @inheritdoc IDiscountVault
    function calcPrice(uint256 numPeriodsElapsed) public view returns (uint256 priceScaled) {
        return _yieldStrategy.calcPrice(address(this), numPeriodsElapsed);
    }

    function price() public view returns (uint256 priceScaled) {
        return calcPrice(currentPeriodsElapsed());
    }

    // TODO - need to account for deposits after _tenor.  e.g. 30 day tenor, deposit on day 31 and redeem on day 32.]
    // NB - this can be done by a lock outside of this contract for example
    function _impliedDepositPrice() internal view returns (uint256 priceScaled) {
        if (currentPeriodsElapsed() < _tenor) return 0;

        return calcPrice(currentPeriodsElapsed() - _tenor);
    }

    function calcYieldSingleTenor(uint256 principal) public view returns (uint256 yield) {
        return _yieldStrategy.calcYield(address(this), principal, 0, tenor());
    }

    // =============== Deposit ===============

    /// @inheritdoc ERC4626Upgradeable
    function _convertToShares(uint256 assets, Math.Rounding /* rounding */ )
        internal
        view
        virtual
        override
        returns (uint256 shares)
    {
        return CalcDiscounted.calcDiscounted(assets, price(), SCALE);
    }

    // =============== Redeem ===============

    /// @inheritdoc ERC4626Upgradeable
    function _convertToAssets(uint256 shares, Math.Rounding /* rounding */ )
        internal
        view
        virtual
        override
        returns (uint256 assets)
    {
        uint256 depositPrice = _impliedDepositPrice();
        // TODO - this is a slash on the entire shares for early redeem.
        // TODO - fine in "previews" but should revert for an actual redeem
        if (depositPrice == 0) return 0;

        uint256 _principal = CalcDiscounted.calcPrincipalFromDiscounted(shares, depositPrice, SCALE);

        return _principal + calcYieldSingleTenor(_principal);
    }

    // =============== Withdraw ===============

    /// @inheritdoc ERC4626Upgradeable
    // TODO - change this to only owner - simplify the vault functions
    function previewWithdraw(uint256 assets)
        public
        view
        override(ERC4626Upgradeable, IERC4626)
        returns (uint256 shares)
    {
        uint256 depositPrice = _impliedDepositPrice();

        return depositPrice == 0 ? 0 : CalcDiscounted.calcDiscounted(assets, depositPrice, SCALE);
    }

    // =============== ERC4626 and ERC20 ===============

    /// @inheritdoc ERC4626Upgradeable
    function decimals() public view virtual override(ERC4626Upgradeable, IERC20Metadata) returns (uint8) {
        return ERC4626Upgradeable.decimals();
    }

    // =============== Utility ===============

    /// @inheritdoc IDiscountVault
    function currentPeriodsElapsed() public view virtual returns (uint256) {
        return Timer.elapsed24Hours(_vaultStartTimestamp);
    }

    /// @inheritdoc IDiscountVault
    function tenor() public view returns (uint256 tenor_) {
        return _tenor;
    }

    /**
     * @notice Internal function to update token transfers.
     * @param from The address transferring the tokens.
     * @param to The address receiving the tokens.
     * @param value The amount of tokens being transferred.
     */
    function _update(address from, address to, uint256 value) internal virtual override {
        ERC20Upgradeable._update(from, to, value);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
