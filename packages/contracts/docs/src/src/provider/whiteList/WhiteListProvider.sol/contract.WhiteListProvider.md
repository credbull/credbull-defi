# WhiteListProvider
[Git Source](https://github.com/credbull/credbull-defi/blob/13cb4799ededd36005edfceebdf3ecc72e5835f9/src/provider/whiteList/WhiteListProvider.sol)

**Inherits:**
[IWhiteListProvider](/src/provider/whiteList/IWhiteListProvider.sol/interface.IWhiteListProvider.md), Ownable2Step


## State Variables
### isWhiteListed
- Track whiteListed addresses


```solidity
mapping(address => bool) public isWhiteListed;
```


## Functions
### constructor


```solidity
constructor(address _owner) Ownable(_owner);
```

### status


```solidity
function status(address receiver) public view override returns (bool);
```

### updateStatus

- Method to update the whiteList status of an address called only by the owner.


```solidity
function updateStatus(address[] calldata _addresses, bool[] calldata _statuses) external override onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_addresses`|`address[]`|- List of addresses value|
|`_statuses`|`bool[]`|- List of statuses to update|


## Errors
### LengthMismatch

```solidity
error LengthMismatch();
```

