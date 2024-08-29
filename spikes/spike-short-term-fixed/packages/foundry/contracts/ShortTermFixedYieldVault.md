# ShortTermFixedYieldVault
[Git Source](https://github.com/credbull/credbull-defi/blob/fd1e90d49bb613b701313238c5417be926ab40b7/contracts/ShortTermFixedYieldVault.sol)

**Inherits:**
ERC721, Ownable2Step, Pausable


## State Variables
### usdcToken
*USDC token address*


```solidity
address public immutable usdcToken;
```


### vaultOpenTime
*Vault start time, configurable by admin*


```solidity
uint256 public vaultOpenTime = type(uint256).max;
```


### tokenCounter
*NFT tokenId counter*


```solidity
uint256 public tokenCounter;
```


### depositInfos
*Store deposit information by tokenID;
if deposited within the same time period, the tokenId is not minted and will be merged into last tokenId*


```solidity
mapping(uint256 => DepositInfo) public depositInfos;
```


### lastTokenId
*the most recently minted tokenId for each depositor*


```solidity
mapping(address => uint256) public lastTokenId;
```


### FIXED_APY

```solidity
uint256 public constant FIXED_APY = 6;
```


### ROLLOVER_BONUS

```solidity
uint256 public constant ROLLOVER_BONUS = 1;
```


### TIME_PERIOD
*This is the unit for all date calculation.*


```solidity
uint256 public constant TIME_PERIOD = 1 days;
```


### LOCK_TIME_PERIODS

```solidity
uint256 public constant LOCK_TIME_PERIODS = 30;
```


### WITHDRAWAL_TIME_PERIODS
*The time period during which withdrawal is allowed after a term's lock has expired.
After this time, the deposit amount is automatically locked into the next term.*


```solidity
uint256 public constant WITHDRAWAL_TIME_PERIODS = 1;
```


### DECIMALS

```solidity
uint256 public constant DECIMALS = 1e18;
```


## Functions
### isVaultOpen


```solidity
modifier isVaultOpen();
```

### constructor


```solidity
constructor(address _usdcToken) ERC721("ShortTermFixedYieldVault", "ST-FY-V") Ownable(msg.sender);
```

### openVault

*Set the start time when users can begin depositing into the Vault.*


```solidity
function openVault(uint256 _vaultOpenTime) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_vaultOpenTime`|`uint256`|Deposits are allowed after this time|


### pause


```solidity
function pause() external onlyOwner;
```

### unpause


```solidity
function unpause() external onlyOwner;
```

### deposit

*User deposits amount into Vault
Users can deposit amount when vault is not paused and open*


```solidity
function deposit(uint256 amount) public whenNotPaused isVaultOpen returns (uint256 tokenId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|the amount of depositing USDC|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|The NFT token ID that a user receives after depositing USDC into the vault.|


### depositWithPermit

If the user has already deposited within the same time period, update the existing deposit

*User deposits amount into Vault
This function can be called to make a deposit without requiring a separate approval step.*


```solidity
function depositWithPermit(
  uint256 amount,
  uint256 deadline,
  uint8 v,
  bytes32 r,
  bytes32 s
) public returns (uint256 tokenId);
```

### withdraw


```solidity
function withdraw(uint256 tokenId, uint256 amount) public whenNotPaused;
```

### withdrawMax


```solidity
function withdrawMax(uint256 tokenId) public;
```

### canWithdraw

*Check whether the invest deposited under the given tokenId can be withdrawn at the current time.*


```solidity
function canWithdraw(uint256 tokenId) public view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenId`|`uint256`|The NFT ID you want to withdraw|


### getCurrentTimePeriodsElapsed

*Return the number of periods that have passed since the Vault was opened.
If TIME_PERIOD is 1 day, this represents the number of days that have passed.*


```solidity
function getCurrentTimePeriodsElapsed() public view returns (uint256 currentTimePeriodsElapsed);
```

### getDepositLockTimePeriods

*Calculates the number of days the amount has been locked.*


```solidity
function getDepositLockTimePeriods(
  uint256 depositTimePeriodsFromOpen
) public view returns (uint256 curDepositLockTimePeriods);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`depositTimePeriodsFromOpen`|`uint256`|The start time period of the lock.|


### getTimePeriodsElapsedInCurrentTerm

*Calculates the elapsed time periods in the current Term.
For example, if the lock time periods is 73 days, it returns 13 days.*


```solidity
function getTimePeriodsElapsedInCurrentTerm(uint256 depositTimePeriodsFromOpen) public view returns (uint256);
```

### getNoOfTermsElapsed

*Calculates the number of terms elapsed in locking
For example, if the lock time periods is 73 days, it returns 2*


```solidity
function getNoOfTermsElapsed(uint256 depositTimePeriodsFromOpen) public view returns (uint256);
```

### calculateCompoundingAmount

*Calculates compounding amount
principal * (1 + r) ^ t = principal * POW(2, t * log2(1 + r))*


```solidity
function calculateCompoundingAmount(
  uint256 principal,
  uint256 apy,
  uint256 noOfTerms,
  uint256 termPeriods
) public pure returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`principal`|`uint256`|the amount of [principal]|
|`apy`|`uint256`|will be used to calculate [r] (FIXED_APY + ROLLOVER_BONUS)|
|`noOfTerms`|`uint256`|[t]|
|`termPeriods`|`uint256`|number of periods in one term (ex: 30 days)|


### calculateAmountWithFixedInterest

*principal * (1 + perTimePeriodInterest * noOfPeriods)*


```solidity
function calculateAmountWithFixedInterest(
  uint256 principal,
  uint256 apy,
  uint256 noOfPeriods
) public pure returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`principal`|`uint256`|the amount of [principal]|
|`apy`|`uint256`|will be used to calculate perTimePeriodInterest (ex: apy / 36500)|
|`noOfPeriods`|`uint256`|[noOfPeriods]|


### getWithdrawalAmount

*Calculates amount (principal + interest)*


```solidity
function getWithdrawalAmount(uint256 tokenId) public view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|withdrawal amount|


### getDepositInfo

Calculate first term yield + principal
Calculate compounding Amount first

*Returns detailed investment information for each tokenId.*


```solidity
function getDepositInfo(
  uint256 tokenId
) external view returns (uint256 remainingLockPeriods, uint256 currentYield, uint256 withdrawalAmount);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`remainingLockPeriods`|`uint256`|The number of days remaining until the withdrawal can be made.|
|`currentYield`|`uint256`|The interest accrued up to the current date.|
|`withdrawalAmount`|`uint256`|The total amount accumulated to current date, including interest.|


## Events
### VaultOpened

```solidity
event VaultOpened(uint256 openTime);
```

### Deposited

```solidity
event Deposited(address indexed user, uint256 amount, uint256 tokenId, uint256 time);
```

### Withdrawn

```solidity
event Withdrawn(address indexed user, uint256 amount, uint256 tokenId, uint256 time);
```

## Errors
### AmountMustBeGreaterThanZero

```solidity
error AmountMustBeGreaterThanZero();
```

### NotOwnerOfNFT

```solidity
error NotOwnerOfNFT();
```

### NoDepositFound

```solidity
error NoDepositFound();
```

### LockPeriodNotEnded

```solidity
error LockPeriodNotEnded();
```

### InvalidOpenTime

```solidity
error InvalidOpenTime();
```

### VaultNotOpen

```solidity
error VaultNotOpen();
```

### WithdrawalNotAllowed

```solidity
error WithdrawalNotAllowed(uint256 tokenId);
```

### AmountIsBiggerThanWithdrawalAmount

```solidity
error AmountIsBiggerThanWithdrawalAmount(uint256 withdrawalAmount);
```

## Structs
### DepositInfo

```solidity
struct DepositInfo {
  uint256 principal;
  uint256 timePeriodsFromOpen;
  uint256 lastWithdrawTermNo;
}
```

