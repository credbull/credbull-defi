# FixedYieldVault
[Git Source](https://github.com/credbull/credbull-defi/blob/13cb4799ededd36005edfceebdf3ecc72e5835f9/src/vault/FixedYieldVault.sol)

**Inherits:**
[MaturityVault](/src/vault/MaturityVault.sol/abstract.MaturityVault.md), [WhiteListPlugin](/src/plugin/WhiteListPlugin.sol/abstract.WhiteListPlugin.md), [WindowPlugin](/src/plugin/WindowPlugin.sol/abstract.WindowPlugin.md), [MaxCapPlugin](/src/plugin/MaxCapPlugin.sol/abstract.MaxCapPlugin.md), AccessControl


## State Variables
### OPERATOR_ROLE
- Hash of operator role


```solidity
bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
```


### FIXED_YIELD
*The fixed yield value in percentage(100) that's promised to the users on deposit.*


```solidity
uint256 private immutable FIXED_YIELD;
```


## Functions
### constructor


```solidity
constructor(FixedYieldVaultParams memory params)
    MaturityVault(params.maturityVault)
    WhiteListPlugin(params.whiteListPlugin)
    WindowPlugin(params.windowPlugin)
    MaxCapPlugin(params.maxCapPlugin);
```

### onDepositOrMint

*- Overridden deposit modifer
Should check for whiteListed address
Should check for deposit window
Should check for max cap*


```solidity
modifier onDepositOrMint(address caller, address receiver, uint256 assets, uint256 shares) override;
```

### onWithdrawOrRedeem

*- Overridden withdraw modifier
Should check for withdraw window
Should check for maturity*


```solidity
modifier onWithdrawOrRedeem(address caller, address receiver, address owner, uint256 assets, uint256 shares) override;
```

### expectedAssetsOnMaturity


```solidity
function expectedAssetsOnMaturity() public view override returns (uint256);
```

### mature

Mature the vault


```solidity
function mature() public override onlyRole(OPERATOR_ROLE);
```

### setMaturityCheck

Toggle check for maturity


```solidity
function setMaturityCheck(bool _setMaturityCheckStatus) public onlyRole(DEFAULT_ADMIN_ROLE);
```

### toggleWhiteListCheck

Toggle check for whiteList


```solidity
function toggleWhiteListCheck() public onlyRole(DEFAULT_ADMIN_ROLE);
```

### toggleWindowCheck

Toggle check for window


```solidity
function toggleWindowCheck() public onlyRole(DEFAULT_ADMIN_ROLE);
```

### setCheckMaxCap

Toggle check for max cap


```solidity
function setCheckMaxCap(bool _checkMaxCapStatus) public onlyRole(DEFAULT_ADMIN_ROLE);
```

### updateMaxCap

Update max cap value


```solidity
function updateMaxCap(uint256 _value) public onlyRole(DEFAULT_ADMIN_ROLE);
```

### updateWindow

Update all window timestamp


```solidity
function updateWindow(uint256 _depositOpen, uint256 _depositClose, uint256 _withdrawOpen, uint256 _withdrawClose)
    public
    onlyRole(DEFAULT_ADMIN_ROLE);
```

### pauseVault

Pause the vault


```solidity
function pauseVault() public onlyRole(DEFAULT_ADMIN_ROLE);
```

### unpauseVault

Unpause the vault


```solidity
function unpauseVault() public onlyRole(DEFAULT_ADMIN_ROLE);
```

### withdrawERC20


```solidity
function withdrawERC20(address[] calldata _tokens) public onlyRole(DEFAULT_ADMIN_ROLE);
```

## Errors
### FixedYieldVault__InvalidOwnerAddress
Error to indicate that the provided owner address is invalid.


```solidity
error FixedYieldVault__InvalidOwnerAddress();
```

### FixedYieldVault__InvalidOperatorAddress
Error to indicate that the provided operator address is invalid.


```solidity
error FixedYieldVault__InvalidOperatorAddress();
```

## Structs
### ContractRoles

```solidity
struct ContractRoles {
    address owner;
    address operator;
    address custodian;
}
```

### FixedYieldVaultParams

```solidity
struct FixedYieldVaultParams {
    MaturityVaultParams maturityVault;
    ContractRoles roles;
    WindowPluginParams windowPlugin;
    WhiteListPluginParams whiteListPlugin;
    MaxCapPluginParams maxCapPlugin;
    uint256 promisedYield;
}
```

