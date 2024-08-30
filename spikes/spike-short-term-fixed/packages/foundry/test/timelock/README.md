# Investment Lock until Maturity

When you invest in the Credbull Product, your Principal is locked for the Product's maturity period, referred to as the Tenor. 
This could be 30 days, 90 days, or another specified duration. During this Tenor (on Deposit), you cannot access or redeem 
your investment. At Maturity, your investment unlocks, allowing you to receive your Principal and Yield or reinvest.

- Deposit: Your investment is locked for the Product's maturity period.  Your investment "locks" until "Tenor" elapsed time.
- Redeem: At maturity, you can redeem your Principal and Yield or reinvest.  Your investment "unlocks" at "Tenor". elapsed time since deposit.

## TimelockIERC1155 Contract Overview

The TimelockIERC1155 contract implements token locking functionality using the ERC1155 Multi Token standard. It allows investments 
to be locked until a specified maturity period, preventing early withdrawal and ensuring that the investment remains committed for the full Tenor.


# Rolling Over Investments at Maturity

Rolling over your investment means that instead of withdrawing your Principal and Yield at Maturity, you automatically reinvest them into the same Product with a new Tenor.

### How It Works
At Maturity, you have a 1-day window to redeem your investment. During this period, you can choose to withdraw your Principal and Yield. 
If you do not take any action within this time, your investment will be automatically rolled over into a new Tenor.

Let’s say you invested $1,000 with a 30-day Tenor. At the end of the 30 days, your investment matures. You then have 1 day to redeem your Principal and Yield. If you do not 
redeem within this 1-day window, your $1,000 plus the Yield will be automatically rolled over into a new 30-day Tenor.

## Rollover Functionality in TimelockIERC1155
The TimelockIERC1155 contract also includes functionality to roll over investments at maturity. The contract burns the unlocked tokens from the 
previous lock period and mints new tokens with a new lock release period, extending the investment's lock.