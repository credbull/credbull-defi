# Simple Interest

**Simple Interest** is interest calculated only on the principal amount, excluding compounding. For more details, see [Wikipedia on Interest](https://en.wikipedia.org/wiki/Interest#Calculation).

###  Formula

`Simple Interest = (IR * P * m) / f`

- **IR**: The simple annual interest rate
- **P**: The Principal (initial amount)
- **m**: The number of time periods elapsed
- **f**: The frequency of applying interest (number of interest periods in a year)

### Interest Example
Imagine Alice invests $1,000 in a Credbull product that returns 12% annualized interest and matures in 30 days. The interest earned would be $10.

`Simple Interest = 0.12 * $1,000 * 30 / 360 = $10`

### Interest Implementation
The SimpleInterest `calcInterest` function in the contract calculates the interest on a given principal based on the number of time periods that have 
elapsed. This function is implemented in the SimpleInterestVault contract to calculate interest, returns and also the Discounted Principal (see below).
```Solidity
/**
 * @notice Calculates the simple interest based on the principal and elapsed time periods.
 * @param principal The initial principal amount.
 * @param numTimePeriodsElapsed The number of time periods for which interest is calculated.
 * @return interest The calculated interest amount.
 */
function calcInterest(uint256 principal, uint256 numTimePeriodsElapsed) external view returns (uint256 interest);
```

[Workbook with further Examples](https://docs.google.com/spreadsheets/d/1Uc6-JW8fJx6PcD_GxczW6EkvacxXuxjZhSDRqB0ZLcY/edit?gid=1548301220#gid=1548301220)

## Discounted Principal

**Discounted Principal** refers to the principal amount excluding interest accrued prior to my investment. This concept ensures that new investors 
do not receive credit for interest that was accrued before their investment was made.

### Discounted Formula
`Discounted Principal =  P - Interest[Prior]`
- **P**: The original Principal (initial amount).
- **Interest[Prior]**: interest that would have accrued if investing from the starting period

### Discounted Example
Now imagine Bob invests $1,000, in the Credbull 12% APY and 30 day maturity on **DAY 2**.  In this case, Discounted Principal would be $999.67.

```
Discounted Principal = P - Interest[Prior] 
= $,1000 - (0.12 * $1,000 * 1 / 360) 
= $1,000 - $0.33 = $999.67
```

### Discounted Implementation
The SimpleInterest `calcDiscounted` function calculates the Discounted Principal after subtracting the interest accrued over a specified number 
of time periods. 
```Solidity
/**
 * @notice Calculates the discounted principal by subtracting the accrued interest.
 * @param principal The initial principal amount.
 * @param numTimePeriodsElapsed The number of time periods for which interest is calculated.
 * @return discounted The discounted principal amount.
 */
function calcDiscounted(uint256 principal, uint256 numTimePeriodsElapsed) external view returns (uint256 discounted);
```

In ERC4626 Vaults, `convertToShares` converts a given amount of assets into shares. In SimpleInterestVault, we have a similar `convertToSharesAtPeriod` 
function to determine the number of shares (Discounted Principal) for the given assets (Principal) at the time period.
```Solidity
/**
 * @notice Converts a given amount of assets to shares based on a specific time period.
 * @param assetsInWei The amount of assets to convert.
 * @param numTimePeriodsElapsed The number of time periods elapsed.
 * @return The number of shares corresponding to the assets at the specified time period.
 */
function convertToSharesAtPeriod(uint256 assetsInWei, uint256 numTimePeriodsElapsed) public view returns (uint256 sharesInWei)
{
    return calcDiscounted(assetsInWei, numTimePeriodsElapsed);
}
```

## Calculating Principal from Discounted Value

**Calculating the Principal from the Discounted Value** involves reversing the discounting process to recover the original principal amount. 

### Principal from Discounted Formula
To calculate the original Principal (P) from the Discounted Value (D), you use the following formula:

`Principal = D + Interest[Prior]`

- **P**: The original Principal (initial amount).
- **D**: The Discounted Principal (Principal minus the accrued interest).
- **Interest[Prior]**: interest that would have accrued if investing from the starting period

### Principal from Discounted Example

Let's stick with Bob and our Credbull Product and the Discounted Principal of $999.67 from above.  In this case, Principal would be the expected $1,000.  

`P = Discounted Principal + Interest[Prior] = $999.67 + $0.33 = $1,000`

### Relationship Between Principal and Discounted

Discounted Principal or just "Discounted" represents the reduction in the principal due to accrued interest over time. By applying the above formula, you can calculate the
original principal from the discounted value, ensuring that the financial relationship between the initial investment and its adjusted value remains consistent.

### Implementation
The SimpleInterest `calcPrincipalFromDiscounted` allows you to recover the original principal from a discounted amount. This function
is required to calculate the correct assets (Principal) for the given shares (discounted Principal) for example at redemption.
```Solidity
/**
* @notice Recovers the original principal from a discounted value by adding back the interest.
* @param discounted The discounted principal amount.
* @param numTimePeriodsElapsed The number of time periods for which interest was calculated.
* @return principal The recovered original principal amount.
*/
function calcPrincipalFromDiscounted(uint256 discounted, uint256 numTimePeriodsElapsed) external view returns (uint256 principal);
```

In ERC4626 Vaults, `convertToAssetes` converts a given amount of shares into assets. In SimpleInterestVault, we have a similar 
`convertToAssetsAtPeriod` function to determine the number of assets (Principal + Accrued Interest) for the given shares (Discounted Principal) 
at the time period.
```Solidity
/**
 * @notice Converts a given amount of shares to assets based on a specific time period.
 * @param sharesInWei The amount of shares to convert.
 * @param numTimePeriodsElapsed The number of time periods elapsed.
 * @return The number of assets corresponding to the shares at the specified time period.
 */
function convertToAssetsAtPeriod(uint256 sharesInWei, uint256 numTimePeriodsElapsed) public view returns (uint256 assetsInWei)
{
    uint256 timePeriodsAtDeposit = (numTimePeriodsElapsed - TENOR);

    uint256 principal = calcPrincipalFromDiscounted(sharesInWei, timePeriodsAtDeposit);

    return principal + calcInterest(principal, TENOR);
}
```

----
# Rolling Over Investment with Discounting

Rolling over your investment means that instead of withdrawing your Principal and Interest at Maturity, you automatically reinvest them into the 
same Product with a new Tenor.

When you roll over, the interest earned during the first period is added to your original Principal (P1), forming a new Principal (P2) 
for the next period. You can choose to fully or partially roll over your investment, with P2 including any amount you reinvest from P1.

## Rollover Example

Alice invests $1,000 in a Credbull product with a 30-day Tenor and 12% APY. She chooses to fully roll over her investment for another 30 days 
after the first Tenor.

### Investment Period 1
Alice earns **$10** in interest for investment period 1.

`Simple Interest = 0.12 * $1,000 * 30 / 360 = $10`

### Investment Period 2
Rather than redeeming, Alice rolls-over her full investment.  

1. Her new Principal(P2) for investment period 2 is **$1,010.**  This includes her 
original Principal(P1) and the interest from period 1.

`Principal (P2) = $1,000 + $10 = $1,010`
   
2. To calculate the Discounted Principal for P2, we need the following calculations

- Interest[Prior], which includes all accrued interest to date.  This is 30 days, or 1 tenor's worth. 

`Interest[Prior] = 0.12 * $1,010 * 30 / 360 = $10.08` 

- Discounted Principal (P2) given Principal (P2) of $1,010 and Interest[Prior] of $10.08 is: 
```
Discounted Principal (P2) = P2 - Interest[Prior]`
Discounted Principal (P2) = $1,010 - $10.08 ≈ $999.92
```

_This calculation shows that the Discounted Principal for investment period 2 is less than Principal(P2) of $1,010 and 
even the original Principal(P1) of $1,000!_

### Rollover Implementation
The TimelockInterestVault `rolloverUnlocked` function reinvests unlocked tokens into a new period.  Rollover is implemented as follows:

- The new Principal (P2) for period 2 is calculated as the original Principal (P1) plus the Interest (P1) earned during the first period. 
The function `convertToAssets`, which is defined as Principal + Interest, is used to calculate this.
- Next, we use `convertToShares` with Principal (P2) to calculate the new shares for period 2. These new shares represent the 
Discounted Principal (P2) for the second period.
- As illustrated in the Rollover Example with Alice, the 'Discounted Principal' (P2) might be less than the 'Discounted Principal' (P1) 
due to interest accrual. In such cases, `rolloverUnlocked` calculates the difference and burns any "excess" amount of shares.
- Finally, we call TimelockIERC1155's `rolloverUnlocked` function to remove the lock on the shares from period 1 and lock them for period 2.


```Solidity

/**
* @notice Rolls over a specified amount of unlocked tokens for a new lock period.
 * @param account The address of the account whose tokens are to be rolled over.
 * @param lockReleasePeriod The period during which these tokens will be released.
 * @param value The amount of tokens to be rolled over.
 */
function rolloverUnlocked(address account, uint256 lockReleasePeriod, uint256 value) public override onlyOwner {
    uint256 principalAndInterestFirstPeriod = convertToAssets(value); // principal + first period interest

    uint256 sharesForNextPeriod = convertToShares(principalAndInterestFirstPeriod); // discounted principal for rollover period
    
    if (value > sharesForNextPeriod) {
        uint256 excessValue = value - sharesForNextPeriod;

        // Burn from ERC1155 (Timelock)
        ERC1155._burn(account, lockReleasePeriod, excessValue);

        // Burn from ERC4626 (Vault)
        SimpleInterestVault._burnInternal(account, excessValue);
    }

    TimelockIERC1155.rolloverUnlocked(account, lockReleasePeriod, sharesForNextPeriod);
}
```

----

# Appendix
### TimelockInterestVault

The TimelockInterestVault contract combines functionality from both the TimelockIERC1155 and SimpleInterestVault contracts. This integration allows the vault to manage investments with both time-locking and interest accrual features. The contract:

- TimelockIERC1155: Manages the locking and unlocking of tokens based on time periods (Tenor).
- SimpleInterestVault: Manages interest accrual and calculations related to the principal and interest earned over time.

### Inverse Relationship Between Discounted and Principal

**The Inverse Relationship** between the Discounted Principal and the Original Principal is useful in verifying our logic whether mathematically or implemented in code.

### Mathematical Proof
We intend to prove that
Original Principal (P) -> Discounted Principal (D) -> Recovered Principal (P')

yields P' = P.

#### Step 1: Calculate the Discounted Principal

Discounted Principal (D) is calculated as:
- `D = P - Interest[Prior]`  // from the Discounted Principal formula
- `Interest[Prior] = (IR * P * m) / f` // from the Simple Interest formula
- `D = P - (IR * P * m) / f` // substitute interest calculation

#### Step 2: Recover the Original Principal from Discounted Principal

To recover the original principal (P') from the Discounted Principal (D), we reverse the previous operation:

- `P' = D + Interest[Prior]`
- `P' = (P - (IR * P * m) / f) + (IR * P * m) / f` // Substituting D from Step 1:

### Step 3: Simplify the Expression
Simplifying the expression:

- `P' = P - (IR * P * m) / f + (IR * P * m) / f`
- `P' = P`  // terms involving the interest cancel out