// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { console2 as console } from "forge-std/console2.sol";

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

enum Term {
    THIRTY_DAYS,
    NINTY_DAYS
}

enum APY {
    SIX_PERCENT,
    EIGHT_PERCENT
}

contract SimpleFixedYieldVault is ERC4626 {
    using Math for uint256;

    error NotSupported();

    uint256 public constant DECIMALS = 18;
    uint256 public constant SCALE = 10 ** DECIMALS;
    uint256 public constant DAYS_IN_YEAR = 365;

    Term public immutable TERM;
    uint256 public immutable SCALED_TERM_INTEREST_RATE;

    constructor(APY _apy, Term _term, IERC20 asset) ERC4626(asset) ERC20("Simple Fixed Yield Claim", "SFYC") {
        // Save the term explicitly, for reading from the contract. Maybe unneeded?
        TERM = _term;
        // CalcuTHIRTY_DAYSerm value.
        uint256 _daysInTerm = _term == Term.THIRTY_DAYS ? 30 : 90;
        uint256 _interestRate = _apy == APY.SIX_PERCENT ? 6 : 8;
        console.log("Days In Term=", _daysInTerm, ", Interest Rate=", _interestRate);
        console.log("Scaled Interest Rate=", _interestRate * SCALE);
        uint256 _scaledDailyInterestRate = (_interestRate * SCALE) / DAYS_IN_YEAR;
        console.log("Scaled Daily Interest Rate=", _scaledDailyInterestRate);
        SCALED_TERM_INTEREST_RATE = _scaledDailyInterestRate * _daysInTerm;
        console.log("Scaled Term Interest Rate=", SCALED_TERM_INTEREST_RATE);
    }

    /**
     * @dev Returns shares to the tune of `assets` increased by the Term Interest Rate. The shares should be
     *  locked until the Term is complete.
     */
    function _convertToShares(uint256 assets, Math.Rounding rounding) internal view override returns (uint256) {
        console.log("Converting to Shares=", assets);
        console.log("Scaled Assets=", assets * SCALE);
        console.log("Scaled Interest Rate=", SCALED_TERM_INTEREST_RATE);
        console.log("Term Interest=", assets.mulDiv(SCALED_TERM_INTEREST_RATE, SCALE * 100));

        return assets + assets.mulDiv(SCALED_TERM_INTEREST_RATE, SCALE * 100, rounding);
    }

    /**
     * @dev Returns assets equal to `shares`.
     */
    function _convertToAssets(uint256 shares, Math.Rounding) internal pure override returns (uint256) {
        return shares;
    }

    /// @dev Lock claim tokens are non-transferrable: ERC-20 transfer is not supported
    function transfer(address, uint256) public pure override(ERC20, IERC20) returns (bool) {
        revert NotSupported();
    }

    /// @dev Lock claim tokens are non-transferrable: ERC-20 allowance is not supported
    function allowance(address, address) public pure override(ERC20, IERC20) returns (uint256) {
        revert NotSupported();
    }

    /// @dev Lock claim tokens are non-transferrable: ERC-20 approve is not supported
    function approve(address, uint256) public pure override(ERC20, IERC20) returns (bool) {
        revert NotSupported();
    }

    /// @dev Lock claim tokens are non-transferrable: ERC-20 transferFrom is not supported
    function transferFrom(address, address, uint256) public pure override(ERC20, IERC20) returns (bool) {
        revert NotSupported();
    }
}
