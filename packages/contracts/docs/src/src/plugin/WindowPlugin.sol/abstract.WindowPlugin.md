# WindowPlugin
[Git Source](https://github.com/credbull/credbull-defi/blob/13cb4799ededd36005edfceebdf3ecc72e5835f9/src/plugin/WindowPlugin.sol)

- A plugin to handle deposit and redemption windows


## State Variables
### depositOpensAtTimestamp
*The timestamp when the vault opens for deposit.*


```solidity
uint256 public depositOpensAtTimestamp;
```


### depositClosesAtTimestamp
*The timestamp when the vault closes for deposit.*


```solidity
uint256 public depositClosesAtTimestamp;
```


### redemptionOpensAtTimestamp
*The timestamp when the vault opens for redemption.*


```solidity
uint256 public redemptionOpensAtTimestamp;
```


### redemptionClosesAtTimestamp
*The timestamp when the vault closes for redemption.*


```solidity
uint256 public redemptionClosesAtTimestamp;
```


### checkWindow
- Flag to check for window


```solidity
bool public checkWindow;
```


## Functions
### validateWindows


```solidity
modifier validateWindows(uint256 _depositOpen, uint256 _depositClose, uint256 _redeemOpen, uint256 _redeemClose);
```

### constructor


```solidity
constructor(WindowPluginParams memory params)
    validateWindows(
        params.depositWindow.opensAt,
        params.depositWindow.closesAt,
        params.redemptionWindow.opensAt,
        params.redemptionWindow.closesAt
    );
```

### _checkIsWithinWindow

Check if a given timestamp is with in a window

*NOTE (JL,2024-07-01): Could we call this '_assertWindow' instead?*


```solidity
function _checkIsWithinWindow(uint256 windowOpensAt, uint256 windowClosesAt) internal view;
```

### _checkIsDepositWithinWindow

Check for deposit window


```solidity
function _checkIsDepositWithinWindow() internal view virtual;
```

### _checkIsRedeemWithinWindow

Check for redemption window


```solidity
function _checkIsRedeemWithinWindow() internal view virtual;
```

### _updateWindow

- Function to update all timestamps

*NOTE (JL,2024-07-01): Why does this not use 2x `Window` instances or a `WindowPluginParams`?
That is their purpose.*


```solidity
function _updateWindow(uint256 _depositOpen, uint256 _depositClose, uint256 _redeemOpen, uint256 _redeemClose)
    internal
    virtual
    validateWindows(_depositOpen, _depositClose, _redeemOpen, _redeemClose);
```

### _toggleWindowCheck

- Function to toggle check for window


```solidity
function _toggleWindowCheck() internal;
```

## Events
### WindowUpdated
Event emitted when the window is updated


```solidity
event WindowUpdated(
    uint256 depositOpensAt, uint256 depositClosesAt, uint256 redemptionOpensAt, uint256 redemptionClosesAt
);
```

### WindowCheckUpdated
Event emitted when the window check is updated


```solidity
event WindowCheckUpdated(bool indexed checkWindow);
```

## Errors
### CredbullVault__OperationOutsideRequiredWindow
Error to revert when operation is outside required window


```solidity
error CredbullVault__OperationOutsideRequiredWindow(uint256 windowOpensAt, uint256 windowClosesAt, uint256 timestamp);
```

### WindowPlugin__IncorrectWindowValues
Error to revert when incorrect window values are provided


```solidity
error WindowPlugin__IncorrectWindowValues(
    uint256 depositOpen, uint256 depositClose, uint256 redeemOpen, uint256 redeemClose
);
```

## Structs
### Window
A Window is essentially a Time Span, denoted by an Opening and Closing Time pair.


```solidity
struct Window {
    uint256 opensAt;
    uint256 closesAt;
}
```

### WindowPluginParams
- Struct to hold window parameters


```solidity
struct WindowPluginParams {
    Window depositWindow;
    Window redemptionWindow;
}
```

