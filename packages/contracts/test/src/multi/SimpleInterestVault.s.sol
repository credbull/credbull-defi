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

// Vault that uses SimpleInterest to calculate Shares per Asset
// - At the start, 1 asset gives 1 share
// - At interestFrequency 1, 1 asset gives 1 - SimpleInterest shares
// - At interestFrequency 2, 1 asset gives 1 - (2 * SimpleInterest) shares,
// - and so on...
//
// This is like having linear deflation over time.
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

    // =============== deposit ===============

    // shares that would be exchanged for the amount of assets
    // at the given numberOfTimePeriodsElapsed
    function convertToSharesAtPeriod(uint256 assetsInWei, uint256 numTimePeriodsElapsed)
        public
        view
        returns (uint256 shares)
    {
        uint256 cycle = calculateCycle(numTimePeriodsElapsed);

        if (cycle == 0) return assetsInWei;

        uint256 interest = calcInterest(assetsInWei, cycle);

        return assetsInWei - interest;
    }

    function previewDeposit(uint256 assets) public view override(ERC4626, IERC4626) returns (uint256) {
        return convertToShares(assets);
    }

    function convertToShares(uint256 assets) public view override(ERC4626, IERC4626) returns (uint256) {
        return convertToSharesAtPeriod(assets, currentTimePeriodsElapsed);
    }

    // =============== redeem ===============

    // convert shares back to the principal
    function convertToPrincipalAtPeriod(uint256 sharesInWei, uint256 numTimePeriodsElapsed)
        public
        view
        returns (uint256 principal)
    {
        uint256 cycle = calculateCycle(numTimePeriodsElapsed);

        if (cycle == 0) return sharesInWei;

        uint256 _principal = calcPrincipalFromDiscounted(sharesInWei, cycle);

        return _principal;
    }

    // asset that would be exchanged for the amount of shares
    // for a given numberOfTimePeriodsElapsed
    // assets = principal + interest
    function convertToAssetsAtPeriod(uint256 sharesInWei, uint256 numTimePeriodsElapsed)
        public
        view
        returns (uint256 assets)
    {
        uint256 principal = convertToPrincipalAtPeriod(sharesInWei, numTimePeriodsElapsed);

        uint256 interest = calcInterest(principal, TENOR); // only ever give one period of interest

        uint256 _assets = principal + interest;

        return _assets;
    }

    function previewRedeem(uint256 shares) public view override(ERC4626, IERC4626) returns (uint256 assets) {
        return convertToAssets(shares);
    }

    function convertToAssets(uint256 shares) public view override(ERC4626, IERC4626) returns (uint256 assets) {
        return convertToAssetsAtPeriod(shares, currentTimePeriodsElapsed);
    }

    function getCurrentTimePeriodsElapsed() public pure returns (uint256 currentTimePeriodElapsed) {
        return currentTimePeriodElapsed;
    }

    function setCurrentTimePeriodsElapsed(uint256 _currentTimePeriodsElapsed) public {
        currentTimePeriodsElapsed = _currentTimePeriodsElapsed;
    }

    // =============== helper ===============

    function getTenor() public view returns (uint256 tenor) {
        return TENOR;
    }

    function calculateCycle(uint256 numTimePeriods) public view returns (uint256 cycle) {
        return numTimePeriods % TENOR;
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
}
