// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { MultiTokenVault } from "@credbull/token/ERC1155/MultiTokenVault.sol";
import { TimerCheats } from "@test/test/timelock/TimerCheats.t.sol";

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract MultiTokenVaultDailyPeriods is MultiTokenVault, TimerCheats {
    uint256 internal immutable ASSET_TO_SHARES_RATIO;
    uint256 internal immutable YIELD_PERCENTAGE;

    constructor(IERC20Metadata asset, uint256 assetToSharesRatio, uint256 yieldPercentage)
        MultiTokenVault(asset)
        TimerCheats(block.timestamp)
    {
        ASSET_TO_SHARES_RATIO = assetToSharesRatio;
        YIELD_PERCENTAGE = yieldPercentage;
    }

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

    function currentPeriodsElapsed() public view override returns (uint256 currentPeriod_) {
        return elapsed24Hours();
    }

    function setCurrentPeriodsElapsed(uint256 currentTimePeriodsElapsed_) public {
        warp24HourPeriods(currentTimePeriodsElapsed_);

        if (currentPeriodsElapsed() != currentTimePeriodsElapsed_) {
            revert Timer__ERC6372InconsistentTime(currentPeriodsElapsed(), currentTimePeriodsElapsed_);
        }
    }
}
