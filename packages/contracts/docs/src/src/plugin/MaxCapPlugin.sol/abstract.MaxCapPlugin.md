# MaxCapPlugin
[Git Source](https://github.com/credbull/credbull-defi/blob/13cb4799ededd36005edfceebdf3ecc72e5835f9/src/plugin/MaxCapPlugin.sol)

- A Plugin to handle MaxCap


## State Variables
### maxCap
Max no.of assets that can be deposited to the vault;


```solidity
uint256 public maxCap;
```


### checkMaxCap
Flag to check for max cap


```solidity
bool public checkMaxCap;
```


## Functions
### constructor


```solidity
constructor(MaxCapPluginParams memory params);
```

### _checkMaxCap

- Function to check for max cap


```solidity
function _checkMaxCap(uint256 value) internal virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`value`|`uint256`|- The value to check against max cap|


### _setCheckMaxCap

- Toggle the max cap check status


```solidity
function _setCheckMaxCap(bool _checkMaxCapStatus) internal virtual;
```

### _updateMaxCap

- Update the max cap value


```solidity
function _updateMaxCap(uint256 _value) internal virtual;
```

## Events
### MaxCapUpdated
Event emitted when the max cap is updated


```solidity
event MaxCapUpdated(uint256 indexed maxCap);
```

### MaxCapCheckUpdated
Event emitted when the max cap check is updated


```solidity
event MaxCapCheckUpdated(bool indexed checkMaxCap);
```

## Errors
### CredbullVault__MaxCapReached

```solidity
error CredbullVault__MaxCapReached();
```

## Structs
### MaxCapPluginParams
- Params for the MaxCap Plugin


```solidity
struct MaxCapPluginParams {
    uint256 maxCap;
}
```

