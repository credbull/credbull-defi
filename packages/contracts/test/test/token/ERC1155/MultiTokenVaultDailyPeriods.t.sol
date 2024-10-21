// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { MultiTokenVault } from "@credbull/token/ERC1155/MultiTokenVault.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract MultiTokenVaultDailyPeriods is Initializable, UUPSUpgradeable, MultiTokenVault {
    uint256 internal ASSET_TO_SHARES_RATIO;
    uint256 internal YIELD_PERCENTAGE;
    uint256 public _currentPeriod;

    function initialize(IERC20Metadata asset, uint256 assetToSharesRatio, uint256 yieldPercentage) public initializer {
        __MultiTokenVault_init(asset);
        ASSET_TO_SHARES_RATIO = assetToSharesRatio;
        YIELD_PERCENTAGE = yieldPercentage;
        _currentPeriod = 0;
    }

    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal virtual override { }

    function calcYield(uint256 principal, uint256, /* depositPeriod */ uint256 /* toPeriod */ )
        public
        view
        returns (uint256 yield)
    {
        return principal * YIELD_PERCENTAGE / 100;
    }

    function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod, uint256 redeemPeriod)
        public
        view
        override
        returns (uint256 assets)
    {
        uint256 principal = shares * ASSET_TO_SHARES_RATIO;

        return principal + calcYield(principal, depositPeriod, redeemPeriod);
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
        return _currentPeriod;
    }

    function setCurrentPeriodsElapsed(uint256 currentTimePeriodsElapsed_) public {
        _currentPeriod = currentTimePeriodsElapsed_;
    }
}
