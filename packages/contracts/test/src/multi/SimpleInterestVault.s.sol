// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { SimpleInterest } from "./SimpleInterest.s.sol";
import { ISimpleInterest } from "./ISimpleInterest.s.sol";
import { IERC4626Interest } from "./IERC4626Interest.s.sol";
import { TimelockVault } from "./TimelockVault.s.sol";

import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";

import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { console2 } from "forge-std/console2.sol";

// Vault that uses SimpleInterest to calculate Shares per Asset
// - At the start, 1 asset gives 1 share
// - As time progresses, the price increases, resulting in fewer shares
//
// TODO - there's a bug in the principal calc for deposit at 0 and redeem at 1
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
        returns (uint256 shares)
    {
        uint256 price = calcPriceAtPeriodWithScale(numTimePeriodsElapsed);

        // Shares = Principal / parPrice
        return assetsInWei.mulDiv(SCALE, price);
    }

    function previewDeposit(uint256 assets) public view override(ERC4626, IERC4626) returns (uint256) {
        return convertToShares(assets);
    }

    function convertToShares(uint256 assets) public view override(ERC4626, IERC4626) returns (uint256) {
        return convertToSharesAtPeriod(assets, currentTimePeriodsElapsed);
    }

    // =============== Redeem ===============

    // asset that would be exchanged for the amount of shares
    // for a given numberOfTimePeriodsElapsed
    // assets = principal + interest
    function convertToAssetsAtPeriod(uint256 sharesInWei, uint256 numTimePeriodsElapsed)
        public
        view
        returns (uint256 assets)
    {
        // trying to redeem before TENOR - just give back the Discounted Amount
        // this is a slash of Principal (and no Interest)
        // NB - according to spec, this function should not revert
        if (numTimePeriodsElapsed < TENOR) return sharesInWei;

        uint256 impliedNumTimePeriodsAtDeposit = (numTimePeriodsElapsed - TENOR);

        uint256 principal = calcPrincipalFromDiscounted(sharesInWei, impliedNumTimePeriodsAtDeposit);

        // we could calculate the assets from the price for symmetry with convertToShares.
        // however, we already have an "easy" way to calculate the returns, so using that.

        return principal + calcInterest(principal, TENOR);
    }

    function previewRedeem(uint256 shares) public view override(ERC4626, IERC4626) returns (uint256 assets) {
        return convertToAssets(shares);
    }

    function convertToAssets(uint256 shares) public view override(ERC4626, IERC4626) returns (uint256 assets) {
        return convertToAssetsAtPeriod(shares, currentTimePeriodsElapsed);
    }

    // =============== Utility ===============

    function getCurrentTimePeriodsElapsed() public pure returns (uint256 currentTimePeriodElapsed) {
        return currentTimePeriodElapsed;
    }

    function setCurrentTimePeriodsElapsed(uint256 _currentTimePeriodsElapsed) public {
        currentTimePeriodsElapsed = _currentTimePeriodsElapsed;
    }

    function calcTenorCycle(uint256 numTimePeriods) public view returns (uint256 cycle) {
        uint256 tenorCycle = numTimePeriods % TENOR;

        console2.log("numTimePeriods, numTimePeriods mod TENOR", numTimePeriods, (numTimePeriods % TENOR));

        return tenorCycle;
    }

    function getTenor() public view returns (uint256 tenor) {
        return TENOR;
    }

    function calcInterest(uint256 principal, uint256 numTimePeriodsElapsed)
        public
        view
        override(ISimpleInterest, SimpleInterest)
        returns (uint256)
    {
        return SimpleInterest.calcInterest(principal, numTimePeriodsElapsed);
    }

    function calcPrincipalFromDiscounted(uint256 discounted, uint256 numTimePeriodsElapsed)
        public
        view
        override(ISimpleInterest, SimpleInterest)
        returns (uint256)
    {
        return SimpleInterest.calcPrincipalFromDiscounted(discounted, numTimePeriodsElapsed);
    }

    function calcPriceAtPeriodWithScale(uint256 numTimePeriodsElapsed)
        public
        view
        override(ISimpleInterest, SimpleInterest)
        returns (uint256)
    {
        if (numTimePeriodsElapsed == 0) return scaleAmount(PAR);

        return SimpleInterest.calcPriceAtPeriodWithScale(numTimePeriodsElapsed);
    }
}
