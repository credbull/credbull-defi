// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { MultiTokenVault } from "@credbull/token/ERC1155/MultiTokenVault.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Timer } from "@credbull/timelock/Timer.sol";
import { IYieldStrategy } from "@credbull/yield/strategy/IYieldStrategy.sol";

contract MultiTokenVaultDailyPeriods is Initializable, UUPSUpgradeable, MultiTokenVault {
    IYieldStrategy public _yieldStrategy;
    uint256 public ASSET_TO_SHARES_RATIO;
    uint256 internal YIELD_PERCENTAGE;
    uint256 public _vaultStartTimestamp;
    uint256 private _maxDeposit;

    function initialize(IERC20Metadata asset, uint256 assetToSharesRatio, uint256 yieldPercentage) public initializer {
        __MultiTokenVault_init(asset);
        ASSET_TO_SHARES_RATIO = assetToSharesRatio;
        _yieldStrategy = new FixedRatioStrategy(yieldPercentage);
        _vaultStartTimestamp = block.timestamp;
    }

    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal virtual override { }

    function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod, uint256 redeemPeriod)
        public
        view
        override
        returns (uint256 assets)
    {
        uint256 principal = shares * ASSET_TO_SHARES_RATIO;

        return principal + _yieldStrategy.calcYield(address(this), principal, depositPeriod, redeemPeriod);
    }

    function convertToSharesForDepositPeriod(uint256 assets, uint256 /* depositPeriod */ )
        public
        view
        override
        returns (uint256 shares)
    {
        return assets / ASSET_TO_SHARES_RATIO;
    }

    function currentPeriodsElapsed() public view override returns (uint256 currentPeriodsElapsed_) {
        return Timer.elapsed24Hours(_vaultStartTimestamp);
    }

    function maxDeposit(address forWhom_) public view virtual override returns (uint256) {
        if (_maxDeposit != 0) {
            return _maxDeposit;
        }
        return super.maxDeposit(forWhom_);
    }

    function setMaxDeposit(uint256 maxDeposit_) public virtual returns (uint256) {
        return _maxDeposit = maxDeposit_;
    }
}

contract FixedRatioStrategy is IYieldStrategy {
    uint256 internal YIELD_PERCENTAGE;

    constructor(uint256 yieldPercentage) {
        YIELD_PERCENTAGE = yieldPercentage;
    }

    /// @dev See {CalcSimpleInterest-calcInterest}
    function calcYield(
        address, /* contextContract */
        uint256 principal,
        uint256, /* fromPeriod */
        uint256 /* toPeriod */
    ) public view virtual returns (uint256 yield) {
        return principal * YIELD_PERCENTAGE / 100;
    }

    /// @dev See {CalcSimpleInterest-calcPriceFromInterest}
    function calcPrice(address, /* contextContract */ uint256 /* numPeriodsElapsed */ )
        public
        view
        virtual
        returns (uint256 price)
    {
        return 0;
    }
}
