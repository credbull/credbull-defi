# WhiteListPlugin
[Git Source](https://github.com/credbull/credbull-defi/blob/13cb4799ededd36005edfceebdf3ecc72e5835f9/src/plugin/WhiteListPlugin.sol)

- A Plugin to handle whiteListing


## State Variables
### WHITELIST_PROVIDER
- Address of the White List Provider.


```solidity
IWhiteListProvider public immutable WHITELIST_PROVIDER;
```


### checkWhiteList
- Flag to check for whiteList


```solidity
bool public checkWhiteList;
```


### DEPOSIT_THRESHOLD_FOR_WHITE_LISTING
- Deposit threshold amount to check for whiteListing


```solidity
uint256 public immutable DEPOSIT_THRESHOLD_FOR_WHITE_LISTING;
```


## Functions
### constructor


```solidity
constructor(WhiteListPluginParams memory params);
```

### _checkIsWhiteListed

- Function to check for whiteListed address


```solidity
function _checkIsWhiteListed(address receiver, uint256 amount) internal view virtual;
```

### _toggleWhiteListCheck

- Function to toggle check for whiteListed address


```solidity
function _toggleWhiteListCheck() internal virtual;
```

## Events
### WhiteListCheckUpdated
Event emitted when the whiteList check is updated


```solidity
event WhiteListCheckUpdated(bool indexed checkWhiteList);
```

## Errors
### CredbullVault__InvalidWhiteListProviderAddress
If an invalid `IWhiteListProvider` Address is provided.


```solidity
error CredbullVault__InvalidWhiteListProviderAddress(address);
```

### CredbullVault__NotWhiteListed
Error to revert if the address is not whiteListed


```solidity
error CredbullVault__NotWhiteListed(address, uint256);
```

## Structs
### WhiteListPluginParams
- Params for the WhiteList Plugin


```solidity
struct WhiteListPluginParams {
    address whiteListProvider;
    uint256 depositThresholdForWhiteListing;
}
```

