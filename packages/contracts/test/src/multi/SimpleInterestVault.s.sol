// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { SimpleInterest } from "./SimpleInterest.s.sol";
import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { TimelockVault } from "./TimelockVault.s.sol";

// Vault that uses SimpleInterest to calculate Shares per Asset
// - At the start, 1 asset gives 1 share
// - At interestFrequency 1, 1 asset gives 1 / APY shares
// - At interestFrequency 2, 1 asset gives 1 / (2 * APY) shares,
// - and so on...
//
// This is like having linear deflation over time.
contract SimpleInterestVault is TimelockVault {
    using Math for uint256;

    SimpleInterest public simpleInterest;
    uint256 public currentTimePeriodsElapsed = 0; // the current interest frequency

    constructor(IERC20 asset, SimpleInterest _simpleInterest)
        TimelockVault(asset, "Simple Interest Rate Claim", "cSIR", 0)
    {
        simpleInterest = _simpleInterest;
    }

    // =============== deposit ===============

    // shares that would be exchanged for the amount of assets
    // at the given numberOfTimePeriodsElapsed
    // shares = assets - simpleInterest
    function convertToSharesAtNumTimePeriodsElapsed(uint256 assets, uint256 numTimePeriodsElapsed)
        public
        view
        returns (uint256 shares)
    {
        if (numTimePeriodsElapsed == 0) return assets;

        uint256 interest = simpleInterest.interest(assets, numTimePeriodsElapsed);

        return assets - interest;
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
    function convertToAssetsAtFrequency(uint256 shares, uint256 numTimePeriodsElapsed)
        public
        view
        returns (uint256 assets)
    {
        if (numTimePeriodsElapsed == 0) return shares;

        uint256 principal = simpleInterest.principalFromDiscounted(shares, numTimePeriodsElapsed);

        uint256 interest = simpleInterest.interest(principal, numTimePeriodsElapsed); // only ever give one period of interest

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
}
