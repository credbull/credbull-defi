// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { SimpleInterest } from "./SimpleInterest.s.sol";
import { TimelockVault } from "./TimelockVault.s.sol";
import { Tenors } from "./Tenors.s.sol";

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
contract SimpleInterestVault is TimelockVault {
    using Math for uint256;

    SimpleInterest public simpleInterest;
    uint256 public currentTimePeriodsElapsed = 0; // the current interest frequency

    Tenors.Tenor public immutable TENOR = Tenors.Tenor.DAYS_30;

    uint256 public immutable SCALE;

    constructor(IERC20 asset, SimpleInterest _simpleInterest)
        TimelockVault(asset, "Simple Interest Rate Claim", "cSIR", 0)
    {
        simpleInterest = _simpleInterest;
        SCALE = _simpleInterest.SCALE(); // calcs require to use the same scaling
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
        if (numTimePeriodsElapsed == 0) return assetsInWei;

        uint256 interest = simpleInterest.calcInterest(assetsInWei, numTimePeriodsElapsed);

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
    function convertToAssetsAtFrequency(uint256 sharesInWei, uint256 numTimePeriodsElapsed)
        public
        view
        returns (uint256 assets)
    {
        if (numTimePeriodsElapsed == 0) return sharesInWei;

        uint256 principal = simpleInterest.calcPrincipalFromDiscounted(sharesInWei, numTimePeriodsElapsed);

        uint256 interest = simpleInterest.calcInterest(principal, numTimePeriodsElapsed); // only ever give one period of interest

        return principal + interest;
    }

    function previewRedeem(uint256 shares) public view override returns (uint256) {
        return convertToAssets(shares);
    }

    function convertToAssets(uint256 shares) public view override returns (uint256) {
        return convertToAssetsAtFrequency(shares, currentTimePeriodsElapsed);
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
        uint256 tenorValue = Tenors.toValue(TENOR);

        uint256 _numTimePeriodsForDeposit = numTimePeriodsElapsed % tenorValue;

        console2.log(
            string.concat(
                "numTimePeriodsElapsed mod tenorValue",
                Strings.toString(numTimePeriodsElapsed),
                " mod ",
                Strings.toString(tenorValue),
                " = ",
                Strings.toString(_numTimePeriodsForDeposit)
            )
        );

        return _numTimePeriodsForDeposit;
    }

    // calculate the numTimePeriodsForRedeem given the numTimePeriodsElapsedAtDeposit
    // early redeems are not prevented, but there is a financial penalty (the principal will not be calculated correctly)
    function calcNumTimePeriodsForRedeem(uint256 numTimePeriodsElapsedAtDeposit)
        public
        view
        returns (uint256 numTimePeriodsForRedeem)
    {
        uint256 tenorValue = Tenors.toValue(TENOR);

        uint256 _numTimePeriodsForRedeem = (numTimePeriodsElapsedAtDeposit + tenorValue) % tenorValue;

        console2.log(
            string.concat(
                "(numTimePeriodsElapsed + tenorValue) mod tenorValue",
                Strings.toString(numTimePeriodsElapsedAtDeposit),
                " + ",
                Strings.toString(tenorValue),
                " mod ",
                Strings.toString(tenorValue),
                " = ",
                Strings.toString(_numTimePeriodsForRedeem)
            )
        );

        return _numTimePeriodsForRedeem;
    }
}
