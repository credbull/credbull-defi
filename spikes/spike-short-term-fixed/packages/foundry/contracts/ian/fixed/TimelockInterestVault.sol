// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { SimpleInterestVault } from "@credbull-spike/contracts/ian/fixed/SimpleInterestVault.sol";
import { TimelockIERC1155 } from "@credbull-spike/contracts/ian/timelock/TimelockIERC1155.sol";
import { IPausable } from "@credbull-spike/contracts/ian/interfaces/IPausable.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { ERC1155Supply } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";

contract TimelockInterestVault is TimelockIERC1155, SimpleInterestVault, Pausable, IPausable {
  constructor(
    address initialOwner,
    IERC20 asset,
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

    // Adjust the difference by burning the excess tokens if the new value is less than the original
    if (value > sharesForNextPeriod) {
      uint256 excessValue = value - sharesForNextPeriod;

      // Burn from ERC1155 (Timelock)
      ERC1155._burn(account, lockReleasePeriod, excessValue);

      // Burn from ERC4626 (Vault)
      SimpleInterestVault._burnInternal(account, excessValue);
    }

    TimelockIERC1155.rolloverUnlocked(account, lockReleasePeriod, sharesForNextPeriod);
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
      revert InsufficientLockedBalance(unlockableAmount, value);
    }

    uint256 principalAndYieldFirstPeriod = convertToAssets(value); // principal + first period interest

    // shares for the next period is the discounted principalAndYield for the first Period
    uint256 _sharesForNextPeriod = convertToShares(principalAndYieldFirstPeriod); // discounted principal for rollover period

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
}
