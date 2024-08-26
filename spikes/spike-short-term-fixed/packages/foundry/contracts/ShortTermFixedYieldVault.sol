//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { ABDKMath64x64 } from "./ABDKMath64x64.sol";

contract ShortTermFixedYieldVault is ERC721, Ownable, Pausable {
  using ABDKMath64x64 for int128;

  /// @dev USDC token address
  IERC20 public immutable usdcToken;
  /// @dev Vault start time, configurable by admin
  uint256 public vaultOpenTime;
  /// @dev NFT tokenId counter
  uint256 public tokenCounter;

  struct DepositInfo {
    uint256 principal;
    uint256 daysFromOpen;
    uint256 lastWithdrawalTime;
  }

  /**
   * @dev Store deposit information by token ID;
   * if deposited within the same window, the tokenId is not minted
   */
  mapping(uint256 => DepositInfo) public depositInfos;
  /**
   * @dev the most recently minted tokenId for each depositor
   */
  mapping(address => uint256) public lastTokenId;

  uint256 public constant FIXED_APY = 6;
  uint256 public constant ROLLOVER_BONUS = 1;
  uint256 public constant LOCK_PERIOD = 30 days;
  uint256 public constant DEPOSIT_WINDOW = 1 days;

  event Deposited(address indexed user, uint256 amount, uint256 tokenId, uint256 time);
  event Withdrawn(address indexed user, uint256 principal, uint256 interest, uint256 tokenId, uint256 time);
  event VaultOpened(uint256 openTime);

  error AmountMustBeGreaterThanZero();
  error USDCTransferFailed();
  error NotOwnerOfNFT();
  error NoDepositFound();
  error LockPeriodNotEnded();
  error InvalidOpenTime();
  error VaultNotOpen();

  constructor(IERC20 _usdcToken) ERC721("ShortTermFixedYieldVault", "ST-FY-V") Ownable(msg.sender) {
    usdcToken = _usdcToken;
    _pause();
  }

  function openVault(uint256 _vaultOpenTime) external onlyOwner {
    if (_vaultOpenTime < block.timestamp) {
      revert InvalidOpenTime();
    }
    vaultOpenTime = _vaultOpenTime;
    _unpause();
    emit VaultOpened(_vaultOpenTime);
  }

  function deposit(uint256 amount) external whenNotPaused {
    if (vaultOpenTime == 0 || block.timestamp < vaultOpenTime) {
      revert VaultNotOpen();
    }

    if (amount == 0) {
      revert AmountMustBeGreaterThanZero();
    }

    usdcToken.transferFrom(msg.sender, address(this), amount);

    uint256 daysFromOpen = (block.timestamp - vaultOpenTime) / 1 days;

    uint256 currentTokenId = lastTokenId[msg.sender];

    if (currentTokenId != 0 && depositInfos[currentTokenId].daysFromOpen == daysFromOpen) {
      /// If the user has already deposited within the same window, update the existing deposit
      depositInfos[currentTokenId].principal += amount;
    } else {
      /// Otherwise, mint a new NFT and create a new deposit
      tokenCounter++;
      uint256 newTokenId = tokenCounter;
      _mint(msg.sender, newTokenId);

      DepositInfo memory newDeposit =
        DepositInfo({ principal: amount, daysFromOpen: daysFromOpen, lastWithdrawalTime: 0 });

      depositInfos[newTokenId] = newDeposit;
      /// Update the last tokenId for this user
      lastTokenId[msg.sender] = newTokenId;

      emit Deposited(msg.sender, amount, newTokenId, block.timestamp);
    }
  }

  function withdraw(uint256 tokenId) external whenNotPaused {
    if (ownerOf(tokenId) != msg.sender) {
      revert NotOwnerOfNFT();
    }

    DepositInfo memory depositInfo = depositInfos[tokenId];
    if (depositInfo.principal == 0) {
      revert NoDepositFound();
    }

    if (block.timestamp < vaultOpenTime + depositInfo.daysFromOpen * 1 days + LOCK_PERIOD) {
      revert LockPeriodNotEnded();
    }

    uint256 elapsedTime = block.timestamp - (vaultOpenTime + depositInfo.daysFromOpen * 1 days);
    uint256 periods = elapsedTime / LOCK_PERIOD;
    uint256 remainingDays = elapsedTime % LOCK_PERIOD;

    uint256 totalAmount = calculateCompoundInterest(
      depositInfo.principal, FIXED_APY, FIXED_APY + ROLLOVER_BONUS, periods * 30 + remainingDays
    );

    /// Burning NFT and deleting its information
    _burn(tokenId);
    delete depositInfos[tokenId];

    /// Transferring principal and interest
    if (!usdcToken.transfer(msg.sender, totalAmount)) {
      revert USDCTransferFailed();
    }

    emit Withdrawn(msg.sender, depositInfo.principal, totalAmount - depositInfo.principal, tokenId, block.timestamp);
  }

  function calculateCompoundInterest(
    uint256 principal,
    uint256 apy,
    uint256 rolloverApy,
    uint256 timeInDays
  ) internal pure returns (uint256) {
    /// Calculate how many periods of 30 days have passed
    uint256 fullPeriods = timeInDays / 30;
    /// Calculate the remaining days
    uint256 remainingDays = timeInDays % 30;

    uint256 totalAmount = principal;

    /// Calculate interest for the first period
    if (fullPeriods >= 1) {
      totalAmount = applyInterest(totalAmount, apy, 30);
      fullPeriods -= 1;
    } else {
      /// In case of less than 30 days
      return applyInterest(totalAmount, apy, timeInDays);
    }

    /// Calculate compound interest for the remaining period
    if (fullPeriods > 0) {
      totalAmount = applyCompoundInterest(totalAmount, rolloverApy, fullPeriods);
    }

    /// Calculate interest for the remaining days
    if (remainingDays > 0) {
      totalAmount = applyInterest(totalAmount, rolloverApy, remainingDays);
    }

    return totalAmount;
  }

  function applyInterest(uint256 principal, uint256 apy, uint256 noOfDays) internal pure returns (uint256) {
    /// Calculate daily interest rate
    int128 dailyRate = ABDKMath64x64.divu(apy * 1e18 / 36500, 1e18);
    /// Calculate compound interest factor based on the number of days
    int128 compoundFactor = ABDKMath64x64.add(ABDKMath64x64.fromInt(1), dailyRate);
    int128 totalFactor = ABDKMath64x64.pow(compoundFactor, noOfDays);
    return ABDKMath64x64.mulu(totalFactor, principal);
  }

  function applyCompoundInterest(uint256 principal, uint256 apy, uint256 periods) internal pure returns (uint256) {
    /// Calculate compound interest for a 30-day period
    int128 periodRate = ABDKMath64x64.divu(apy * 30 * 1e18 / 36500, 1e18);
    int128 compoundFactor = ABDKMath64x64.add(ABDKMath64x64.fromInt(1), periodRate);
    int128 totalFactor = ABDKMath64x64.pow(compoundFactor, periods);
    return ABDKMath64x64.mulu(totalFactor, principal);
  }

  function getDepositInfo(
    uint256 tokenId
  ) external view returns (uint256 principal, uint256 daysFromOpen, uint256 lastWithdrawalTime) {
    DepositInfo storage depositInfo = depositInfos[tokenId];
    return (depositInfo.principal, depositInfo.daysFromOpen, depositInfo.lastWithdrawalTime);
  }
}
