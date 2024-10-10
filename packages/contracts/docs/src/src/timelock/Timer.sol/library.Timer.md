# Timer
[Git Source](https://github.com/credbull/credbull-defi/blob/13cb4799ededd36005edfceebdf3ecc72e5835f9/src/timelock/Timer.sol)

*Please note when used on "period-aware" contracts/libs, e.g. `CalcInterest`, `MultiTokenVault`:
- `Daily` periods - use elapsed24Hours().  However, a day is not always 24 hours due to leap seconds.
- `Seconds` periods - use elapsedSeconds().  Fine for CalcInterest, not for MultiTokenVault depositPeriods.  Too many periods to iterate!
- `Monthly` or `Annual` - not supported due to the (more) complex rules*


## Functions
### timestamp

*returns the current timepoint (timestamp mode)*


```solidity
function timestamp() internal view returns (uint256 timestamp_);
```

### clock

*returns the current timepoint (timestamp mode) in uint256*


```solidity
function clock() internal view returns (uint48 clock_);
```

### CLOCK_MODE

*returns the clock mode as required by EIP-6372.  For timestamp, MUST return mode=timestamp.*


```solidity
function CLOCK_MODE() internal pure returns (string memory);
```

### elapsedSeconds

*returns the elapsed time in seconds since starTime*


```solidity
function elapsedSeconds(uint256 startTimestamp) internal view returns (uint256 elapsedSeconds_);
```

### elapsedMinutes

*returns the elapsed time in minutes since starTime*


```solidity
function elapsedMinutes(uint256 startTimestamp) internal view returns (uint256 elapsedMinutes_);
```

### elapsed24Hours

*returns the elapsed 24-hour periods since starTime*


```solidity
function elapsed24Hours(uint256 startTimestamp) internal view returns (uint256 elapsed24hours_);
```

## Errors
### Timer__StartTimeNotReached

```solidity
error Timer__StartTimeNotReached(uint256 currentTime, uint256 startTime);
```

