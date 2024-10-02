# Investment Lock until Maturity

When you invest in the Credbull Product, your Principal is locked for the Product's maturity period, referred to as the Tenor. 
This could be 30 days, 90 days, or another specified duration. During this Tenor (on Deposit), you cannot access or redeem 
your investment. At Maturity, your investment unlocks, allowing you to receive your Principal and Interest or reinvest.

- Deposit: Your investment is locked for the Product's maturity period.  Your investment "locks" until "Tenor" elapsed time.
- Redeem: At maturity, you can redeem your Principal and Interest or reinvest.  Your investment "unlocks" at "Tenor". elapsed time since deposit.

## Lock on Deposit

### Lock Example 
Alice invests $1,000 in a Credbull product with a 30-day lock period. Her 1,000 tokens are locked for 30 days, during which she cannot 
redeem her investment.

### Lock Implementation
The `lock` function is responsible for locking a specified amount of tokens for a particular account until a given release period. 
In TimelockIERC1155, the `lock` function mints ERC1155 tokens at the lockReleasePeriod to represent the locked amount.
```Solidity
/**
 * @notice Locks a specified amount of tokens for a particular account until a given release period.
 * @param account The address of the account whose tokens are to be locked.
 * @param lockReleasePeriod The period during which these tokens will be released.
 * @param value The amount of tokens to be locked.
 */
function lock(address account, uint256 lockReleasePeriod, uint256 value) public override onlyOwner {
    _mint(account, lockReleasePeriod, value, "");
}
```

## Unlock for Redeem

### Unlock Example
If Alice tries to unlock her $1,000 investment before the 30-day period ends, the attempt will fail. After 30 days, she can successfully 
unlock and redeem her investment.

### Unlock Implementation
The `unlock` function allows tokens to be made available for transfer or redemption once the lock release period has been reached.
In TimelockIERC1155, the `unlock` function burns the locked ERC1155 tokens, effectively releasing the amount that was previously locked.
```Solidity
/**
 * @notice Unlocks a specified amount of tokens for a particular account once the lock release period has been reached.
 * @param account The address of the account whose tokens are to be unlocked.
 * @param lockReleasePeriod The period during which these tokens will be released.
 * @param value The amount of tokens to be unlocked.
 */
function unlock(address account, uint256 lockReleasePeriod, uint256 value) public onlyOwner {
    if (currentPeriod < lockReleasePeriod) {
        revert LockDurationNotExpired(currentPeriod, lockReleasePeriod);
    }

    uint256 unlockableAmount = previewUnlock(account, lockReleasePeriod);
    if (unlockableAmount < value) {
        revert InsufficientLockedBalance(unlockableAmount, value);
    }

    _burn(account, lockReleasePeriod, value);
}
```
----
## Rolling Over Investments

Rolling over your investment means that instead of withdrawing your Principal and Interest at Maturity, you automatically reinvest them into the 
same Product for an additional "tenor" period of time.

### Rollover Example
Alice invests $1,000 with a 30-day Tenor. After 30 days, her investment matures, giving her 1 day to redeem. If she doesn't redeem within that 
window, her $1,000 plus the Interest automatically rolls over into a new 30-day Tenor.

### Rollover Implementation
The `rolloverUnlocked` function reinvests unlocked tokens by rolling them over into a new lock period. In the TimelockIERC1155 implementation, 
this function burns the unlocked tokens and mints new tokens for the new lock period.
```Solidity
/**
 * @notice Rolls over a specified amount of unlocked tokens for a new lock period.
 * @param account The address of the account whose tokens are to be rolled over.
 * @param lockReleasePeriod The period during which these tokens will be released.
 * @param value The amount of tokens to be rolled over.
 */
function rolloverUnlocked(address account, uint256 lockReleasePeriod, uint256 value) public virtual override onlyOwner
{
    uint256 unlockableAmount = previewUnlock(account, lockReleasePeriod);

    if (value > unlockableAmount) {
        revert InsufficientLockedBalance(unlockableAmount, value);
    }

    _burn(account, lockReleasePeriod, value);

    uint256 rolloverLockReleasePeriod = lockReleasePeriod + lockDuration;

    _mint(account, rolloverLockReleasePeriod, value, "");
}

```
