//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { ABDKMath64x64 } from "./ABDKMath64x64.sol";

contract ShortTermFixedYieldVault is ERC721, Ownable2Step, Pausable {
  using ABDKMath64x64 for int128;
  using ABDKMath64x64 for uint256;

  /// @dev USDC token address
  address public immutable usdcToken;
  /// @dev Vault start time, configurable by admin
  uint256 public vaultOpenTime = type(uint256).max;
  /// @dev NFT tokenId counter
  uint256 public tokenCounter;

  struct DepositInfo {
    uint256 principal;
    uint256 timePeriodsFromOpen;
  }

  /**
   * @dev Store deposit information by tokenID;
   * if deposited within the same time period, the tokenId is not minted and will be merged into last tokenId
   */
  mapping(uint256 => DepositInfo) public depositInfos;
  /**
   * @dev the most recently minted tokenId for each depositor
   */
  mapping(address => uint256) public lastTokenId;

  uint256 public constant FIXED_APY = 10;

  /// @dev This is the unit for all date calculation.
  uint256 public constant TIME_PERIOD = 1 days;
  uint256 public constant LOCK_TIME_PERIODS = 30;

  /**
   * @dev The time period during which withdrawal is allowed after a term's lock has expired.
   * After this time, the deposit amount is automatically locked into the next term.
   */
  uint256 public constant WITHDRAWAL_TIME_PERIODS = 1;
  uint256 public constant DECIMALS = 1e18;

  event VaultOpened(uint256 openTime);
  event Deposited(address indexed user, uint256 amount, uint256 tokenId, uint256 time);
  event Withdrawn(address indexed user, uint256 amount, uint256 tokenId, uint256 time);

  error AmountMustBeGreaterThanZero();
  error NotOwnerOfNFT();
  error NoDepositFound();
  error LockPeriodNotEnded();
  error InvalidOpenTime();
  error VaultNotOpen();
  error WithdrawalNotAllowed(uint256 tokenId);
  error AmountIsBiggerThanWithdrawalAmount(uint256 withdrawalAmount);

  modifier isVaultOpen() {
    if (block.timestamp < vaultOpenTime) {
      revert VaultNotOpen();
    }
    _;
  }

  constructor(
    address _usdcToken
  ) ERC721("ShortTermFixedYieldVault", "ST-FY-V") Ownable(msg.sender) {
    usdcToken = _usdcToken;
    _pause();
  }

  /**
   * @dev Set the start time when users can begin depositing into the Vault.
   * @param _vaultOpenTime Deposits are allowed after this time
   */
  function openVault(
    uint256 _vaultOpenTime
  ) external onlyOwner {
    if (_vaultOpenTime < block.timestamp) {
      revert InvalidOpenTime();
    }
    vaultOpenTime = _vaultOpenTime;

    _unpause();

    emit VaultOpened(_vaultOpenTime);
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  /**
   * @dev User deposits amount into Vault
   * Users can deposit amount when vault is not paused and open
   * @param amount the amount of depositing USDC
   * @return tokenId The NFT token ID that a user receives after depositing USDC into the vault.
   */
  function deposit(
    uint256 amount
  ) public whenNotPaused isVaultOpen returns (uint256 tokenId) {
    if (amount == 0) {
      revert AmountMustBeGreaterThanZero();
    }

    IERC20(usdcToken).transferFrom(msg.sender, address(this), amount);

    uint256 currentTimePeriodsElapsed = getCurrentTimePeriodsElapsed();

    tokenId = lastTokenId[msg.sender];

    /**
     * If the user has already deposited within the same time period, update the existing deposit
     */
    if (tokenId != 0 && depositInfos[tokenId].timePeriodsFromOpen == currentTimePeriodsElapsed) {
      depositInfos[tokenId].principal += amount;
    } else {
      // Otherwise, mint a new NFT and create a new deposit
      tokenId = tokenCounter;
      tokenId += 1;

      _mint(msg.sender, tokenId);

      DepositInfo memory newDeposit = DepositInfo({ principal: amount, timePeriodsFromOpen: currentTimePeriodsElapsed });

      depositInfos[tokenId] = newDeposit;

      // Update the last tokenId for this user
      lastTokenId[msg.sender] = tokenId;
      tokenCounter = tokenId;
    }

    emit Deposited(msg.sender, amount, tokenId, block.timestamp);
    return tokenId;
  }

  /**
   * @dev User deposits amount into Vault
   * This function can be called to make a deposit without requiring a separate approval step.
   */
  function depositWithPermit(
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public returns (uint256 tokenId) {
    IERC20Permit(usdcToken).permit(msg.sender, address(this), amount, deadline, v, r, s);

    return deposit(amount);
  }

  function withdraw(uint256 tokenId, uint256 amount) public whenNotPaused {
    if (amount == 0) {
      revert AmountMustBeGreaterThanZero();
    }

    if (ownerOf(tokenId) != msg.sender) {
      revert NotOwnerOfNFT();
    }

    uint256 withdrawalAmount = getWithdrawalAmount(tokenId);

    if (amount > withdrawalAmount) {
      revert AmountIsBiggerThanWithdrawalAmount(withdrawalAmount);
    }

    if (amount == withdrawalAmount) {
      _burn(tokenId);
      delete depositInfos[tokenId];
    } else {
      DepositInfo memory depositInfo = depositInfos[tokenId];

      depositInfos[tokenId] = DepositInfo({
        principal: withdrawalAmount - amount,
        timePeriodsFromOpen: getTimePeriodsInCurrentTermStart(depositInfo.timePeriodsFromOpen)
      });
    }

    IERC20(usdcToken).transfer(msg.sender, amount);

    emit Withdrawn(msg.sender, amount, tokenId, block.timestamp);
  }

  function withdrawMax(
    uint256 tokenId
  ) public {
    uint256 withdrawalAmount = getWithdrawalAmount(tokenId);

    withdraw(tokenId, withdrawalAmount);
  }

  /**
   * @dev Check whether the invest deposited under the given tokenId can be withdrawn at the current time.
   * @param tokenId The NFT ID you want to withdraw
   */
  function canWithdraw(
    uint256 tokenId
  ) public view returns (bool) {
    uint256 timePeriodsFromOpen = depositInfos[tokenId].timePeriodsFromOpen;

    return getTimePeriodsElapsedInCurrentTerm(timePeriodsFromOpen) <= WITHDRAWAL_TIME_PERIODS
      && getNoOfTermsElapsed(timePeriodsFromOpen) > 0;
  }

  /**
   * @dev Return the number of periods that have passed since the Vault was opened.
   * If TIME_PERIOD is 1 day, this represents the number of days that have passed.
   */
  function getCurrentTimePeriodsElapsed() public view returns (uint256 currentTimePeriodsElapsed) {
    return (block.timestamp - vaultOpenTime) / TIME_PERIOD;
  }

  /**
   * @dev Calculates the number of days the amount has been locked.
   * @param depositTimePeriodsFromOpen The start time period of the lock. // uint days
   */
  function getDepositLockTimePeriods(
    uint256 depositTimePeriodsFromOpen
  ) public view returns (uint256 curDepositLockTimePeriods) {
    curDepositLockTimePeriods = getCurrentTimePeriodsElapsed() - depositTimePeriodsFromOpen;

    return curDepositLockTimePeriods <= 1 ? 0 : curDepositLockTimePeriods - 1;
  }

  /**
   * @dev Calculates the elapsed time periods in the current Term.
   * For example, if the lock time periods is 73 days, it returns 13 days.
   */
  function getTimePeriodsElapsedInCurrentTerm(
    uint256 depositTimePeriodsFromOpen
  ) public view returns (uint256) {
    unchecked {
      return getDepositLockTimePeriods(depositTimePeriodsFromOpen) % LOCK_TIME_PERIODS;
    }
  }

  /**
   * @dev Calculates the number of terms elapsed in locking
   * For example, if the lock time periods is 73 days, it returns 2
   */
  function getNoOfTermsElapsed(
    uint256 depositTimePeriodsFromOpen
  ) public view returns (uint256) {
    return getDepositLockTimePeriods(depositTimePeriodsFromOpen) / LOCK_TIME_PERIODS;
  }

  /**
   * @dev Returns the starting time periods of the current term.
   * This is used when updating DepositInfo of tokenId when the user withdraws a partial amount.
   */
  function getTimePeriodsInCurrentTermStart(
    uint256 depositTimePeriodsFromOpen
  ) public view returns (uint256) {
    return getNoOfTermsElapsed(depositTimePeriodsFromOpen) * LOCK_TIME_PERIODS + depositTimePeriodsFromOpen;
  }

  /**
   * @dev Calculates compounding amount
   * principal * (1 + r) ^ t = principal * POW(2, t * log2(1 + r))
   * @param principal the amount of [principal]
   * @param apy will be used to calculate [r] (FIXED_APY)
   * @param noOfTerms [t]
   * @param termPeriods number of periods in one term (ex: 30 days)
   */
  function calculateCompoundingAmount(
    uint256 principal,
    uint256 apy,
    uint256 noOfTerms,
    uint256 termPeriods
  ) public pure returns (uint256) {
    // caculate rate
    int128 termRate = ((apy * termPeriods * DECIMALS) / 36500).divu(DECIMALS);

    // 1 + rate
    int128 compoundFactor = termRate.add(ABDKMath64x64.fromUInt(1));

    // [noOfTerms] * Log2(1 + rate)
    int128 exponent = compoundFactor.log_2().mul(noOfTerms.fromUInt());

    // principal * (2 ^ exponent)
    return exponent.exp_2().mulu(principal);
  }

  /**
   * @dev principal * (1 + perTimePeriodInterest * noOfPeriods)
   * @param principal the amount of [principal]
   * @param apy will be used to calculate perTimePeriodInterest (ex: apy / 36500)
   * @param noOfPeriods [noOfPeriods]
   */
  function calculateAmountWithFixedInterest(
    uint256 principal,
    uint256 apy,
    uint256 noOfPeriods
  ) public pure returns (uint256) {
    uint256 scaledAmount = principal * (DECIMALS + apy * noOfPeriods * DECIMALS / 36500);

    return scaledAmount / DECIMALS;
  }

  /**
   * @dev Calculates withdrawal amount based on current date, that user can withdraw from the vault
   * This withdrawal amount is always less than accumulated amount
   * @return accumulatedAmount amount
   */
  function getWithdrawalAmount(
    uint256 tokenId
  ) public view returns (uint256) {
    return _calculateLastTermWithdrawal(tokenId);
  }

  /**
   * @dev Calculates accumlated amount based on current date
   * @return accumulatedAmount amount
   */
  function calculateAccumulatedAmount(
    uint256 tokenId
  ) public view returns (uint256) {
    uint256 accumulatedAmount = _calculateLastTermWithdrawal(tokenId);

    DepositInfo memory depositInfo = depositInfos[tokenId];

    uint256 timePeriodsElapsedInCT = getTimePeriodsElapsedInCurrentTerm(depositInfo.timePeriodsFromOpen);

    if (timePeriodsElapsedInCT > 0) {
      accumulatedAmount = calculateAmountWithFixedInterest(accumulatedAmount, FIXED_APY, timePeriodsElapsedInCT);
    }

    return accumulatedAmount;
  }

  /**
   * @dev Returns detailed investment information for each tokenId.
   * @return periodsUntilTermEnd The number of days remaining until the withdrawal can be made.
   * @return currentYield The interest accrued up to the current date.
   * @return accumulatedAmount The total amount accumulated to current date, including interest.
   */
  function getDepositInfo(
    uint256 tokenId
  ) external view returns (uint256 periodsUntilTermEnd, uint256 currentYield, uint256 accumulatedAmount) {
    DepositInfo memory depositInfo = depositInfos[tokenId];

    periodsUntilTermEnd = LOCK_TIME_PERIODS - getTimePeriodsElapsedInCurrentTerm(depositInfo.timePeriodsFromOpen);
    accumulatedAmount = calculateAccumulatedAmount(tokenId);
    currentYield = accumulatedAmount - depositInfo.principal;
  }

  function _calculateLastTermWithdrawal(
    uint256 tokenId
  ) internal view returns (uint256) {
    DepositInfo memory depositInfo = depositInfos[tokenId];

    if (depositInfo.principal == 0) {
      return 0;
    }

    uint256 noOfTermsElapsed = getNoOfTermsElapsed(depositInfo.timePeriodsFromOpen);

    uint256 withdrawalAmount = depositInfo.principal;

    if (noOfTermsElapsed > 0) {
      withdrawalAmount = calculateCompoundingAmount(withdrawalAmount, FIXED_APY, noOfTermsElapsed, LOCK_TIME_PERIODS);
    }

    return withdrawalAmount;
  }
}
