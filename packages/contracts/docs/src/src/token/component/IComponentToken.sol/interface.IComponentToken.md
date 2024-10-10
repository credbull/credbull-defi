# IComponentToken
[Git Source](https://github.com/credbull/credbull-defi/blob/13cb4799ededd36005edfceebdf3ecc72e5835f9/src/token/component/IComponentToken.sol)

*Interface for buying and selling tokens.
Similar to ERC-4626 Tokenized Vault standard, here:
- currencyToken is the "asset" ERC20 token.  e.g. USDC or another stablecoin
- componentToken is the "share" ERC20 token.  i.e. the Vault token
//*


## Functions
### requestBuy

Submit a request to send currencyTokenAmount of CurrencyToken to buy ComponentToken


```solidity
function requestBuy(uint256 currencyTokenAmount) external returns (uint256 requestId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`currencyTokenAmount`|`uint256`|Amount of CurrencyToken to send|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`requestId`|`uint256`|Unique identifier for the buy request|


### requestSell

Submit a request to send componentTokenAmount of ComponentToken to sell for CurrencyToken


```solidity
function requestSell(uint256 componentTokenAmount) external returns (uint256 requestId);
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
function executeBuy(address requestor, uint256 requestId, uint256 currencyTokenAmount, uint256 componentTokenAmount)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`requestor`|`address`|Address of the user or smart contract that requested the buy|
|`requestId`|`uint256`|Unique identifier for the request|
|`currencyTokenAmount`|`uint256`|Amount of CurrencyToken to send|
|`componentTokenAmount`|`uint256`|Amount of ComponentToken to receive|


### executeSell

Executes a request to sell ComponentToken for CurrencyToken


```solidity
function executeSell(address requestor, uint256 requestId, uint256 currencyTokenAmount, uint256 componentTokenAmount)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`requestor`|`address`|Address of the user or smart contract that requested the sell|
|`requestId`|`uint256`|Unique identifier for the request|
|`currencyTokenAmount`|`uint256`|Amount of CurrencyToken to receive|
|`componentTokenAmount`|`uint256`|Amount of ComponentToken to send|


### getVersion

Returns the version of the ComponentToken interface


```solidity
function getVersion() external view returns (uint256 version);
```

