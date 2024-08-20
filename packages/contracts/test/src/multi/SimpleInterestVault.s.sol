// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { SimpleInterest } from "./SimpleInterest.s.sol";
import { TimelockVault } from "./TimelockVault.s.sol";

import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { console2 } from "forge-std/console2.sol";

// Vault that uses SimpleInterest to calculate Shares per Asset
// - At the start, 1 asset gives 1 share
// - At interestFrequency 1, 1 asset gives 1 - SimpleInterest shares
// - At interestFrequency 2, 1 asset gives 1 - (2 * SimpleInterest) shares,
// - and so on...
//
// This is like having linear deflation over time.
contract SimpleInterestVault is SimpleInterest, TimelockVault {
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
    // shares = assets - simpleInterest
    function convertToSharesAtNumTimePeriodsElapsed(uint256 assetsInWei, uint256 numTimePeriodsElapsed)
        public
        view
        returns (uint256 shares)
    {
        uint256 cycle = modTenor(numTimePeriodsElapsed);

        if (cycle == 0) return assetsInWei;

        uint256 interest = calcInterest(assetsInWei, cycle);

        return assetsInWei - interest;
    }

    function previewDeposit(uint256 assets) public view override returns (uint256) {
        return convertToShares(assets);
    }

    function convertToShares(uint256 assets) public view override returns (uint256) {
        return convertToSharesAtNumTimePeriodsElapsed(assets, currentTimePeriodsElapsed);
    }

    // =============== redeem ===============

    // asset that would be exchanged for the amount of shares
    // for a given numberOfTimePeriodsElapsed.  to calculate the non-discounted "principal" from the shares
    // assets = principal + interest
    function convertToPrincipalAtNumTimePeriodsElapsed(uint256 sharesInWei, uint256 numTimePeriodsElapsed)
        public
        view
        returns (uint256 assets)
    {
        uint256 cycle = modTenor(numTimePeriodsElapsed);

        if (cycle == 0) return sharesInWei;

        uint256 principal = calcPrincipalFromDiscounted(sharesInWei, cycle);

        return principal;
    }

    function modTenor(uint256 numTimePeriods) public view returns (uint256) {
        if (numTimePeriods == 0) return 0;

        return numTimePeriods % TENOR;
    }

    // asset that would be exchanged for the amount of shares
    // for a given numberOfTimePeriodsElapsed.  to calculate the non-discounted "principal" from the shares
    // assets = principal + interest
    function convertToAssetsAtNumTimePeriodsElapsed(uint256 sharesInWei, uint256 numTimePeriodsElapsed)
        public
        view
        returns (uint256 assets)
    {
        uint256 principal = convertToPrincipalAtNumTimePeriodsElapsed(sharesInWei, numTimePeriodsElapsed);

        uint256 interest = calcInterest(principal, TENOR); // only ever give one period of interest

        return principal + interest;
    }

    function previewRedeem(uint256 shares) public view override returns (uint256) {
        return convertToAssets(shares);
    }

    function convertToAssets(uint256 shares) public view override returns (uint256) {
        return convertToAssetsAtNumTimePeriodsElapsed(shares, currentTimePeriodsElapsed);
    }

    /**
     * @dev See {IERC4626-previewDeposit}.
     */
    function setCurrentTimePeriodsElapsed(uint256 _currentTimePeriodsElapsed) public {
        currentTimePeriodsElapsed = _currentTimePeriodsElapsed;
    }

    // calculate the vaultNumTimePeriods given the numTimePeriodsElapsed
    // the vault cycles through dates based on the vault tenor
    function calcNumTimePeriodsForDeposit(uint256 numTimePeriodsElapsed)
        public
        view
        returns (uint256 numTimePeriodsForRedeem)
    {
        uint256 _numTimePeriodsForDeposit = numTimePeriodsElapsed % TENOR;

        console2.log(
            string.concat(
                "numTimePeriodsElapsed mod tenorValue",
                Strings.toString(numTimePeriodsElapsed),
                " mod ",
                Strings.toString(TENOR),
                " = ",
                Strings.toString(_numTimePeriodsForDeposit)
            )
        );

        return _numTimePeriodsForDeposit;
    }
}
