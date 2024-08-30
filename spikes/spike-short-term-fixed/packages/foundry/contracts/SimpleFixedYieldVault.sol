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

/**
 * @notice An example Fixed Yield, Short Term Vault predicated on pre-calculating the interest on `asset`, adding it to
 *  `asset` and returning that as `shares`. At withdrawal, `shares` provide 1:1 assets.
 * @dev This subverts the ERC4626 asset/share ratio/calculation. Is this a possible security risk? I doubt it as the
 *  calcultion is based upon the Interest Rate and does not depends on the contents of the Vault.
 */
contract SimpleFixedYieldVault is ERC4626 {
    using Math for uint256;

    error NotSupported();

    uint256 public constant DAYS_IN_YEAR = 365;

    Term public immutable TERM;
    uint256 public immutable SCALED_TERM_INTEREST_RATE;

    constructor(APY _apy, Term _term, IERC20 asset) ERC4626(asset) ERC20("Simple Fixed Yield Claim", "SFYC") {
        // Save the term explicitly, for reading from the contract. Maybe unneeded?
        TERM = _term;

        // NOTE (JL,2024-08-26): We use the Asset/Share Scaling to calculate the Scaled Term Interest Rate.
        uint256 _daysInTerm = _term == Term.THIRTY_DAYS ? 30 : 90;
        uint256 _interestRate = _apy == APY.SIX_PERCENT ? 6 : 8;
        uint256 _scaledDailyInterestRate = _interestRate * scale() / DAYS_IN_YEAR;
        SCALED_TERM_INTEREST_RATE = _scaledDailyInterestRate * _daysInTerm;

        console.log("Days In Term=", _daysInTerm, ", Interest Rate=", _interestRate);
        console.log("Scaled Interest Rate=", _interestRate * scale());
        console.log("Scaled Daily Interest Rate=", _scaledDailyInterestRate);
        console.log("Scaled Term Interest Rate=", SCALED_TERM_INTEREST_RATE);
    }

    /**
     * @dev The Number Scaling effective for the Vault Shares. This is the same scaling as for the `asset`.
     */
    function scale() private view returns (uint256) {
        return 10 ** decimals();
    }

    /**
     * @dev Returns shares to the tune of `assets` plus the Term Interest Rate.
     */
    function _convertToShares(uint256 assets, Math.Rounding rounding) internal view override returns (uint256) {
        console.log(
            "Assets=", assets, " + Term Interest=", assets.mulDiv(SCALED_TERM_INTEREST_RATE, 100 * scale(), rounding)
        );

        return assets + assets.mulDiv(SCALED_TERM_INTEREST_RATE, 100 * scale(), rounding);
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
