// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { SimpleInterest } from "./SimpleInterest.s.sol";
import { IERC4626Interest } from "./IERC4626Interest.s.sol";
import { TimelockVault } from "./TimelockVault.s.sol";

import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";

import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

// Vault that uses SimpleInterest to calculate Shares per Asset
// - At the start, 1 asset gives 1 share
// - At numPeriod of N, 1 asset gives as discounted amount of "1 - N * interest"
contract SimpleInterestVault is IERC4626Interest, SimpleInterest, TimelockVault {
    using Math for uint256;

    uint256 public currentTimePeriodsElapsed = 0; // the current interest frequency

    // how many time periods for vault redeem
    // should use the same time unit (day / month or years) as the interest frequency
    uint256 public immutable TENOR;

    constructor(IERC20 asset, uint256 interestRatePercentage, uint256 frequency, uint256 tenor)
        SimpleInterest(interestRatePercentage, frequency)
        TimelockVault(asset, "Simple Interest Rate Claim", "cSIR", 0)
    {
        TENOR = tenor;
    }

    // =============== Deposit ===============

    function convertToSharesAtPeriod(uint256 assetsInWei, uint256 numTimePeriodsElapsed)
        public
        view
        returns (uint256 sharesInWei)
    {
        if (assetsInWei < SCALE) return 0; // no shares for fractional assets

        return calcDiscounted(assetsInWei, numTimePeriodsElapsed);
    }

    function previewDeposit(uint256 assetsInWei)
        public
        view
        override(ERC4626, IERC4626)
        returns (uint256 sharesInWei)
    {
        return convertToShares(assetsInWei);
    }

    function convertToShares(uint256 assetsInWei)
        public
        view
        override(ERC4626, IERC4626)
        returns (uint256 sharesInWei)
    {
        return convertToSharesAtPeriod(assetsInWei, currentTimePeriodsElapsed);
    }

    // =============== Redeem ===============

    // asset that would be exchanged for the amount of shares
    // for a given numberOfTimePeriodsElapsed
    // assets = principal + interest
    function convertToAssetsAtPeriod(uint256 sharesInWei, uint256 numTimePeriodsElapsed)
        public
        view
        returns (uint256 assetsInWei)
    {
        if (sharesInWei < SCALE) return 0; // no assets for fractional shares

        // trying to redeem before TENOR - just give back the Discounted Amount
        // this is a slash of Principal (and no Interest)
        // NB - according to spec, this function should not revert
        if (numTimePeriodsElapsed < TENOR) return sharesInWei;

        uint256 impliedNumTimePeriodsAtDeposit = (numTimePeriodsElapsed - TENOR);

        uint256 principal = calcPrincipalFromDiscounted(sharesInWei, impliedNumTimePeriodsAtDeposit);

        return principal + calcInterest(principal, TENOR);
    }

    function previewRedeem(uint256 sharesInWei) public view override(ERC4626, IERC4626) returns (uint256 assetsInWei) {
        return convertToAssets(sharesInWei);
    }

    function convertToAssets(uint256 sharesInWei)
        public
        view
        override(ERC4626, IERC4626)
        returns (uint256 assetsInWei)
    {
        return convertToAssetsAtPeriod(sharesInWei, currentTimePeriodsElapsed);
    }

    // =============== Utility ===============

    function getCurrentTimePeriodsElapsed() public pure returns (uint256 currentTimePeriodElapsed) {
        return currentTimePeriodElapsed;
    }

    function setCurrentTimePeriodsElapsed(uint256 _currentTimePeriodsElapsed) public {
        currentTimePeriodsElapsed = _currentTimePeriodsElapsed;
    }

    function getTenor() public view returns (uint256 tenor) {
        return TENOR;
    }
}
