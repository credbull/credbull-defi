// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { ISimpleInterest } from "@credbull/contracts/interfaces/ISimpleInterest.s.sol";
import { SimpleInterest } from "@credbull/contracts/fixed/SimpleInterest.s.sol";
import { IERC4626Interest } from "@credbull/contracts/interfaces/IERC4626Interest.s.sol";
import { IProduct } from "@credbull/contracts/interfaces/IProduct.s.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

import { Math } from "@openzeppelin/contracts//utils/math/Math.sol";

// Vault that uses SimpleInterest to calculate Shares per Asset
// - At the start, 1 asset gives 1 share
// - At numPeriod of N, 1 asset gives as discounted amount of "1 - N * interest"
contract SimpleInterestVault is IERC4626Interest, SimpleInterest, ERC4626, IProduct, ERC20Burnable {
    using Math for uint256;

    uint256 public currentTimePeriodsElapsed = 0; // the current number of time periods elapse

    // how many time periods for vault redeem
    // should use the same time unit (day / month or years) as the interest frequency
    uint256 public immutable TENOR;

    constructor(IERC20 asset, uint256 interestRatePercentage, uint256 frequency, uint256 tenor)
        SimpleInterest(interestRatePercentage, frequency)
        ERC4626(asset)
        ERC20("Simple Interest Rate Claim", "cSIR")
    {
        TENOR = tenor;
    }

    // =============== Deposit ===============

    function deposit(uint256 assets, address receiver)
        public
        virtual
        override(IERC4626, ERC4626, IProduct)
        returns (uint256)
    {
        return ERC4626.deposit(assets, receiver);
    }

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

    function redeem(uint256 shares, address receiver, address owner)
        public
        virtual
        override(IERC4626, ERC4626, IProduct)
        returns (uint256)
    {
        return ERC4626.redeem(shares, receiver, owner);
    }

    // TODO - not fully implemented.   need to unlock the specific shares specific to this period.
    function redeemAtPeriod(uint256 shares, address receiver, address owner, uint256 redeemTimePeriod)
        external
        returns (uint256 assets)
    {
        if (currentTimePeriodsElapsed != redeemTimePeriod) {
            revert RedeemTimePeriodNotSupported(currentTimePeriodsElapsed, redeemTimePeriod);
        }

        return redeem(shares, receiver, owner);
    }

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

        uint256 principal = _calcPrincipalFromSharesAtPeriod(sharesInWei, numTimePeriodsElapsed);

        return principal + calcInterest(principal, TENOR);
    }

    // asset that would be exchanged for the amount of shares
    // for a given numberOfTimePeriodsElapsed
    // assets = principal + interest
    function _calcPrincipalFromSharesAtPeriod(uint256 sharesInWei, uint256 numTimePeriodsElapsed)
        internal
        view
        returns (uint256 principal)
    {
        if (sharesInWei < SCALE) return 0; // no assets for fractional shares

        // trying to redeem before TENOR - just give back the Discounted Amount
        // this is a slash of Principal (and no Interest)
        // NB - according to spec, this function should not revert
        if (numTimePeriodsElapsed < TENOR) return sharesInWei;

        uint256 impliedNumTimePeriodsAtDeposit = (numTimePeriodsElapsed - TENOR);

        uint256 _principal = calcPrincipalFromDiscounted(sharesInWei, impliedNumTimePeriodsAtDeposit);

        return _principal;
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

    // =============== ERC4626 and ERC20 ===============

    function decimals() public view virtual override(ERC20, ERC4626, IERC20Metadata) returns (uint8) {
        return ERC4626.decimals();
    }

    function _burnInternal(address account, uint256 value) internal virtual {
        _spendAllowance(account, _msgSender(), value);
        _burn(account, value);
    }

    // =============== Utility ===============

    function getCurrentTimePeriodsElapsed()
        public
        view
        virtual
        override(IERC4626Interest, IProduct)
        returns (uint256)
    {
        return currentTimePeriodsElapsed;
    }

    function setCurrentTimePeriodsElapsed(uint256 _currentTimePeriodsElapsed)
        public
        virtual
        override(IERC4626Interest, IProduct)
    {
        currentTimePeriodsElapsed = _currentTimePeriodsElapsed;
    }

    function getTenor() public view returns (uint256 tenor) {
        return TENOR;
    }

    // =============== IProduct Interface ===============

    function getFrequency()
        public
        view
        override(ISimpleInterest, SimpleInterest, IProduct)
        returns (uint256 frequency)
    {
        return SimpleInterest.getFrequency();
    }

    function getInterestInPercentage()
        public
        view
        override(ISimpleInterest, SimpleInterest, IProduct)
        returns (uint256 interestRateInPercentage)
    {
        return SimpleInterest.getInterestInPercentage();
    }
}
