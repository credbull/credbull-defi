# LiquidContinuousMultiTokenVault
[Git Source](https://github.com/credbull/credbull-defi/blob/13cb4799ededd36005edfceebdf3ecc72e5835f9/src/yield/LiquidContinuousMultiTokenVault.sol)

**Inherits:**
Initializable, UUPSUpgradeable, [MultiTokenVault](/src/token/ERC1155/MultiTokenVault.sol/abstract.MultiTokenVault.md), [IComponentToken](/src/token/component/IComponentToken.sol/interface.IComponentToken.md), [TimelockAsyncUnlock](/src/timelock/TimelockAsyncUnlock.sol/abstract.TimelockAsyncUnlock.md), [TripleRateContext](/src/yield/context/TripleRateContext.sol/abstract.TripleRateContext.md), AccessControlEnumerableUpgradeable, IERC6372

*Vault MUST be a Daily frequency of 360 or 365.  `depositPeriods` will be used as IERC1155 `ids`.
- Seconds frequency is NOT SUPPORTED.  Results in too many periods to manage as IERC155 ids
- Month or Annual frequency is NOT SUPPORTED.  Requires a more advanced timer e.g. an external Oracle.*


## State Variables
### _yieldStrategy

```solidity
IYieldStrategy public _yieldStrategy;
```


### _redeemOptimizer

```solidity
IRedeemOptimizer public _redeemOptimizer;
```


### _vaultStartTimestamp

```solidity
uint256 public _vaultStartTimestamp;
```


### ZERO_REQUEST_ID

```solidity
uint256 private constant ZERO_REQUEST_ID = 0;
```


### OPERATOR_ROLE

```solidity
bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
```


### UPGRADER_ROLE

```solidity
bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
```


## Functions
### constructor


```solidity
constructor();
```

### initialize


```solidity
function initialize(VaultParams memory vaultParams) public initializer;
```

### _initRole


```solidity
function _initRole(string memory roleName, bytes32 role, address account) private;
```

### _authorizeUpgrade


```solidity
function _authorizeUpgrade(address newImplementation) internal view override onlyRole(UPGRADER_ROLE);
```

### convertToSharesForDepositPeriod


```solidity
function convertToSharesForDepositPeriod(uint256 assets, uint256) public view override returns (uint256 shares);
```

### redeemForDepositPeriod


```solidity
function redeemForDepositPeriod(
    uint256 shares,
    address receiver,
    address owner,
    uint256 depositPeriod,
    uint256 redeemPeriod
) public virtual override returns (uint256 assets);
```

### _redeemForDepositPeriodAfterUnlock

redeemForDepositPeriod after unlocking.  calling function MUST call unlock() prior.


```solidity
function _redeemForDepositPeriodAfterUnlock(
    uint256 shares,
    address receiver,
    address owner,
    uint256 depositPeriod,
    uint256 redeemPeriod
) internal virtual returns (uint256 assets);
```

### convertToAssetsForDepositPeriod


```solidity
function convertToAssetsForDepositPeriod(uint256 shares, uint256 depositPeriod, uint256 redeemPeriod)
    public
    view
    override
    returns (uint256 assets);
```

### requestBuy

Submit a request to send currencyTokenAmount of CurrencyToken to buy ComponentToken

*- buys can be directly executed.*


```solidity
function requestBuy(uint256 currencyTokenAmount) public virtual override returns (uint256 requestId_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`currencyTokenAmount`|`uint256`|Amount of CurrencyToken to send|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`requestId_`|`uint256`|requestId Unique identifier for the buy request|


### requestSell

Submit a request to send componentTokenAmount of ComponentToken to sell for CurrencyToken


```solidity
function requestSell(uint256 componentTokenAmount) public virtual override returns (uint256 requestId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`componentTokenAmount`|`uint256`|Amount of ComponentToken to send|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`requestId`|`uint256`|Unique identifier for the sell request|


### executeBuy

Executes a request to buy ComponentToken with CurrencyToken


```solidity
function executeBuy(address requestor, uint256, uint256 currencyTokenAmount, uint256 componentTokenAmount)
    public
    override;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`requestor`|`address`|Address of the user or smart contract that requested the buy|
|`<none>`|`uint256`||
|`currencyTokenAmount`|`uint256`|Amount of CurrencyToken to send|
|`componentTokenAmount`|`uint256`|Amount of ComponentToken to receive|


### executeSell

Executes a request to sell ComponentToken for CurrencyToken


```solidity
function executeSell(address requestor, uint256 requestId, uint256, uint256 componentTokenAmount) public override;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`requestor`|`address`|Address of the user or smart contract that requested the sell|
|`requestId`|`uint256`|Unique identifier for the request|
|`<none>`|`uint256`||
|`componentTokenAmount`|`uint256`|Amount of ComponentToken to send|


### setRedeemOptimizer

*set the IRedeemOptimizer*


```solidity
function setRedeemOptimizer(IRedeemOptimizer redeemOptimizer) public onlyRole(OPERATOR_ROLE);
```

### setYieldStrategy

*set the YieldStrategy*


```solidity
function setYieldStrategy(IYieldStrategy yieldStrategy) public onlyRole(OPERATOR_ROLE);
```

### calcYield

*yield based on the associated yieldStrategy*


```solidity
function calcYield(uint256 principal, uint256 fromPeriod, uint256 toPeriod) public view returns (uint256 yield);
```

### calcPrice

*price is not used in Vault calculations.  however, 1 asset = 1 share, implying a price of 1*


```solidity
function calcPrice(uint256) public view virtual returns (uint256 price);
```

### lock

Locks `amount` of tokens for `account` at the given `depositPeriod`.

*- users should call deposit() instead that returns shares*


```solidity
function lock(address account, uint256 depositPeriod, uint256 amount) public onlyRole(OPERATOR_ROLE);
```

### lockedAmount


```solidity
function lockedAmount(address account, uint256 depositPeriod) public view override returns (uint256 lockedAmount_);
```

### setReducedRate

Sets the 'reduced' Interest Rate to be effective from the `effectiveFromPeriod_` Period.

*Reverts with [TripleRateContext_PeriodRegressionNotAllowed] if `effectiveFromPeriod_` is before the
current Period.
Emits [CurrentPeriodRateChanged] upon mutation. Access is `virtual` to enable Access Control override.*


```solidity
function setReducedRate(uint256 reducedRateScaled_, uint256 effectiveFromPeriod_)
    public
    override
    onlyRole(OPERATOR_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`reducedRateScaled_`|`uint256`|The scaled 'reduced' Interest Rate percentage.|
|`effectiveFromPeriod_`|`uint256`|The Period from which the `reducedRateScaled_` is effective.|


### setReducedRateAtCurrent

Sets the `reducedRateScaled_` against the Current Period.

*Convenience method for setting the Reduced Rate agains the current Period.
Reverts with [TripleRateContext_PeriodRegressionNotAllowed] if current Period is before the
stored current Period (the setting).  Emits [CurrentPeriodRateChanged] upon mutation.*


```solidity
function setReducedRateAtCurrent(uint256 reducedRateScaled_) public onlyRole(OPERATOR_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`reducedRateScaled_`|`uint256`|The scaled percentage 'reduced' Interest Rate.|


### setVaultStartTimestamp

*set the vault start timestamp*


```solidity
function setVaultStartTimestamp(uint256 vaultStartTimestamp) public onlyRole(OPERATOR_ROLE);
```

### currentPeriodsElapsed

*vault is 0 based. so currentPeriodsElapsed() = currentPeriod() - 0*


```solidity
function currentPeriodsElapsed() public view override returns (uint256 numPeriodsElapsed_);
```

### currentPeriod

*vault is 0 based. so currentPeriodsElapsed() = currentPeriod() - 0*


```solidity
function currentPeriod() public view override returns (uint256 currentPeriod_);
```

### clock

*Clock used for flagging checkpoints. Can be overridden to implement timestamp based checkpoints (and voting).*


```solidity
function clock() public view returns (uint48 clock_);
```

### CLOCK_MODE

*Description of the clock*


```solidity
function CLOCK_MODE() public pure returns (string memory);
```

### pause


```solidity
function pause() public onlyRole(OPERATOR_ROLE);
```

### unpause


```solidity
function unpause() public onlyRole(OPERATOR_ROLE);
```

### supportsInterface


```solidity
function supportsInterface(bytes4 interfaceId)
    public
    view
    override(MultiTokenVault, AccessControlEnumerableUpgradeable)
    returns (bool);
```

### getVersion


```solidity
function getVersion() public pure returns (uint256 version);
```

## Errors
### LiquidContinuousMultiTokenVault__InvalidFrequency

```solidity
error LiquidContinuousMultiTokenVault__InvalidFrequency(uint256 frequency);
```

### LiquidContinuousMultiTokenVault__InvalidAuthAddress

```solidity
error LiquidContinuousMultiTokenVault__InvalidAuthAddress(string authName, address authAddress);
```

### LiquidContinuousMultiTokenVault__AmountMismatch

```solidity
error LiquidContinuousMultiTokenVault__AmountMismatch(uint256 amount1, uint256 amount2);
```

### LiquidContinuousMultiTokenVault__UnlockPeriodMismatch

```solidity
error LiquidContinuousMultiTokenVault__UnlockPeriodMismatch(uint256 unlockPeriod1, uint256 unlockPeriod2);
```

### LiquidContinuousMultiTokenVault__InvalidComponentTokenAmount

```solidity
error LiquidContinuousMultiTokenVault__InvalidComponentTokenAmount(
    uint256 componentTokenAmount, uint256 unlockRequestedAmount
);
```

## Structs
### VaultAuth

```solidity
struct VaultAuth {
    address owner;
    address operator;
    address upgrader;
}
```

### VaultParams

```solidity
struct VaultParams {
    VaultAuth vaultAuth;
    IERC20Metadata asset;
    IYieldStrategy yieldStrategy;
    IRedeemOptimizer redeemOptimizer;
    uint256 vaultStartTimestamp;
    uint256 redeemNoticePeriod;
    TripleRateContext.ContextParams contextParams;
}
```

