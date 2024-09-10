// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { SimpleInterestVault } from "@credbull-spike/contracts/ian/fixed/SimpleInterestVault.sol";
import { TimelockIERC1155 } from "@credbull-spike/contracts/ian/timelock/TimelockIERC1155.sol";
import { IPausable } from "@credbull-spike/contracts/ian/interfaces/IPausable.sol";

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { ERC1155Supply } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";

import { console2 } from "forge-std/console2.sol";


contract TimelockInterestVault is TimelockIERC1155, SimpleInterestVault, Pausable, IPausable {

  constructor(
    address initialOwner,
    IERC20Metadata asset,
    uint256 interestRatePercentage,
    uint256 frequency,
    uint256 tenor
  ) TimelockIERC1155(initialOwner) SimpleInterestVault(asset, interestRatePercentage, frequency, tenor) { }

  // we want the supply of the ERC20 token - not the locks
  function totalSupply() public view virtual override(ERC1155Supply, IERC20, ERC20) returns (uint256) {
    return ERC20.totalSupply();
  }

  function deposit(
    uint256 assets,
    address receiver
  ) public override(SimpleInterestVault) whenNotPaused returns (uint256 shares) {
    shares = SimpleInterestVault.deposit(assets, receiver);

    // Call the internal _lock function instead, which handles the locking logic
    _lockInternal(receiver, currentTimePeriodsElapsed + TENOR, shares);

    return shares;
  }

  function redeem(
    uint256 shares,
    address receiver,
    address owner
  ) public override(SimpleInterestVault) whenNotPaused returns (uint256 assets) {
    // First, unlock the shares if possible
    _unlockInternal(owner, currentTimePeriodsElapsed, shares);

    // Then, redeem the shares for the corresponding amount of assets
    return SimpleInterestVault.redeem(shares, receiver, owner);
  }

  /**
   * @notice Rolls over a specified amount of unlocked tokens for a new lock period.
   * @param account The address of the account whose tokens are to be rolled over.
   * @param lockReleasePeriod The period during which these tokens will be released.
   * @param value The amount of tokens to be rolled over.
   */
  function rolloverUnlocked(address account, uint256 lockReleasePeriod, uint256 value) public override onlyOwner {
    uint256 sharesForNextPeriod = previewConvertSharesForRollover(account, lockReleasePeriod, value);

    // TODO: this probably only makes sense if lockReleasePeriod == currentTimePeriodsElapsed.  assert as such.

    // case where the Shares[P1] for first period are LESS than Shares[P2], e.g. due to Rollover Bonus
    if (sharesForNextPeriod > value) {
      uint256 deficientValue = sharesForNextPeriod - value;

      TimelockIERC1155._lockInternal(account, currentTimePeriodsElapsed, deficientValue); // mint from ERC1155 (Timelock)

      ERC20._mint(account, deficientValue); // mint from ER20/ERC4626 (Vault)
    }

    // case where the Shares[P1] for first period are GREATER than Shares[P2], e.g. due to Discounting
    if (value > sharesForNextPeriod) {
      uint256 excessValue = value - sharesForNextPeriod;

      ERC1155._burn(account, lockReleasePeriod, excessValue); // burn from ERC1155 (Timelock)

      ERC20._burn(account, excessValue); // burn from ERC20/ERC4626 (Vault)
    }

    TimelockIERC1155.rolloverUnlocked(account, lockReleasePeriod, sharesForNextPeriod);
  }

  function calcRolloverBonus(address /* account */, uint256 /* lockReleasePeriod */, uint256 value)
  public view override returns (uint256 rolloverBonus) {
    uint256 rolloverBonusScaled = _calcInterestWithScale(value, TENOR, 1, FREQUENCY);

    return _unscale(rolloverBonusScaled);
  }

  /**
   *  When rolloing over, we need to re-calculate the shares to account for the passage of time
   *  Any difference will need to be credited or debited from the current balance
   * NB - this does revert unlike ERC4626 preview meethods.
   */
  function previewConvertSharesForRollover(
    address account,
    uint256 lockReleasePeriod,
    uint256 value
  ) public view returns (uint256 sharesForNextPeriod) {
    uint256 unlockableAmount = this.previewUnlock(account, lockReleasePeriod);

    // Ensure that the account has enough unlockable tokens to roll over
    if (value > unlockableAmount) {
      revert InsufficientLockedBalanceAtPeriod(account, unlockableAmount, value, lockReleasePeriod);
    }

    uint256 principalAndYieldFirstPeriod = convertToAssets(value); // principal + first period interest

    uint256 rolloverBonus = calcRolloverBonus(account, lockReleasePeriod, principalAndYieldFirstPeriod); // bonus for rolled over assets

    uint256 assetsForNextPeriod = principalAndYieldFirstPeriod + rolloverBonus;

    // shares for the next period is the Discounted PrincipalAndYield for the first Period + Rollover bonus
    uint256 _sharesForNextPeriod = convertToShares(assetsForNextPeriod); // discounted principal for rollover period

    return _sharesForNextPeriod;
  }

  function getLockDuration() public view override returns (uint256 lockDuration) {
    return TENOR;
  }

  function getCurrentPeriod() public view virtual override returns (uint256 currentPeriod) {
    return currentTimePeriodsElapsed;
  }

  function setCurrentPeriod(uint256 _currentPeriod) public override {
    setCurrentTimePeriodsElapsed(_currentPeriod);
  }

  function pause() public onlyOwner {
    Pausable._pause();
  }

  function unpause() public onlyOwner {
    Pausable._unpause();
  }

  /**
   * @notice Returns the interest earned by a user for a specific window of time.
     * @param user The address of the user.
     * @param window The specific window of time for which to calculate the interest earned.
     * @return The amount of interest earned by the user for the specified window.
     */
  function interestEarnedForWindow(address user, uint256 window) public view override returns (uint256) {

  }

  /**
   * @notice Returns the total interest earned by a user over all windows
     * @param user The address of the user.
     * @return The total amount of interest earned by the user.
     */
  function totalInterestEarned(address user) public view override returns (uint256) {
    uint256[] memory userLockPeriods = getLockPeriods(user);
    uint256[] memory principals = _getPrincipalsForLockPeriods(user, userLockPeriods);

    uint256 totalInterest = 0;

    for (uint256 i = 0; i < userLockPeriods.length; i++) {
      uint256 redeemPeriod = userLockPeriods[i];
      uint256 depositPeriod = redeemPeriod - TENOR;
      uint256 timePeriodsElapsed = getCurrentTimePeriodsElapsed() - depositPeriod;

      uint256 principal = principals[i];

      uint256 interest = calcInterest(principal, timePeriodsElapsed);

      totalInterest += interest;
    }

    return totalInterest;
  }

  /**
   * @notice Returns the total amount of assets deposited by a user.
     * @param user The address of the user.
     * @return The total amount of assets deposited by the user.
     */
  function totalUserDeposit(address user) public view override returns (uint256) {
    uint256[] memory userLockPeriods = getLockPeriods(user);

    // get the principal amounts for each lock period
    uint256[] memory principals = _getPrincipalsForLockPeriods(user, userLockPeriods);

    uint256 totalDeposit = 0;

    // Sum up all the principal amounts
    for (uint256 i = 0; i < principals.length; i++) {
      totalDeposit += principals[i];
    }

    return totalDeposit;
  }

/**
 * @notice Helper function that takes an array of lock periods and returns an array of principal values.
 * @param user The address of the user.
 * @param lockPeriods An array of lock periods.
 * @return principals An array of uint256 representing the principal amount for each lock period.
 */
  function _getPrincipalsForLockPeriods(address user, uint256[] memory lockPeriods) internal view returns (uint256[] memory) {
    // Create an array to hold the principal amounts for each lock period
    uint256[] memory principals = new uint256[](lockPeriods.length);

    // Iterate through the lock periods and calculate the principal for each
    for (uint256 i = 0; i < lockPeriods.length; i++) {
      uint256 redeemPeriod = lockPeriods[i];

      uint256 shares = balanceOf(user, redeemPeriod);

      // Convert shares to principal for the current lock period
      uint256 principal = _convertToPrincipalAtPeriod(shares, redeemPeriod);

      // Store the principal in the array
      principals[i] = principal;
    }

    return principals;
  }
}
