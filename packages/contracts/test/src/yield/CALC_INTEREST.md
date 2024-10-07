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

## Price

**Price** shows the growth of interest over time for a Principal of 1.  Price at at day 1 is 1 and increases as interest is applied daily.

### Price Formula
Price is defined as Principal of "1" plus the interest that has accrued over time:
`Price = P + Simple Interest`
`Price = P + (IR * P * m) / f` //substituting formula for Simple Interest
`Price = 1 + (IR * m) / f` // substituting Principal = 1

### Price Example
Let's look at Price for our Credbull 12% APY and 30 day maturity product over different days.
- Price Day 0  ` 1 + (0.12 *  0) / 360 = 1`
- Price Day 1  ` 1 + (0.12 *  1) / 360 ≈ 1.00033`
- Price Day 30 ` 1 + (0.12 * 30) / 360 = 1.01`
---

## Discounted Principal

**Discounted Principal** refers to the principal amount, adjusted by the price to account for accrued interest. This concept ensures 
that new investors do not receive credit for interest that accrued prior to their investment.

### Discounted Formula
`Discounted Principal = P / Price`
- **P**: The original Principal (initial amount). 
- **Price**: Represents the interest accrued over time for a Principal of 1.

### Discounted Example
Now imagine Bob invests $1,000 in the Credbull 12% APY and 30 day maturity on **DAY 1**.  In this case, Bob's Discounted Principal would be $999.67.

```
Price(Day 1)  = 1 + (0.12 * 1 / 360) = 1.00033
Discounted = P / Price = $1,000 / 1.00033 ≈ $999.67
```

### Discounted Implementation
The SimpleInterest `calcDiscounted` function calculates the Discounted Principal by dividing the principal by the Price.
```Solidity
/**
* @notice Calculates the discounted principal by dividing the principal by the price.
* @param principal The initial principal amount.
* @param numTimePeriodsElapsed The number of time periods for which interest is calculated.
* @return The discounted principal amount.
*/
function calcDiscounted(uint256 principal, uint256 numTimePeriodsElapsed) public view returns (uint256);
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
To calculate the original Principal from the Discounted Principal, you use the following formula:

`P = D * Price`

- **P**: The original Principal (initial amount).
- **D**: The Discounted Principal (Principal divided by Price).
- **Price**: Represents the interest accrued over time for a Principal of 1.

### Principal from Discounted Example

Let's stick with Bob and our Credbull Product and the Discounted Principal of $999.67 from above.  Reversing give us the expected Principal of $1,000.  

```
Price(Day 1) = 1 + (0.12 * 1 / 360) = 1.00033
P = P * Price = $999.67 * 1.00033 ≈ $1,000
```

### Relationship Between Principal and Discounted

Discounted Principal or just "Discounted" represents the reduction in the principal due to accrued interest over time. By applying the above formula, you can calculate the
original principal from the discounted value, ensuring that the financial relationship between the initial investment and its adjusted value remains consistent.

### Implementation
The SimpleInterest `calcPrincipalFromDiscounted` allows you to recover the original principal from a discounted amount. This function
is required to calculate the correct assets (Principal) for the given shares (discounted Principal) for example at redemption.
```Solidity
/**
 * @notice Recovers the original principal from a discounted value by multiplying it with the Price.
 * @param discounted The discounted principal amount.
 * @param numTimePeriodsElapsed The number of time periods for which interest was calculated.
 * @return principal The recovered original principal amount.
 */
function calcPrincipalFromDiscounted(uint256 discounted, uint256 numTimePeriodsElapsed) external view returns (uint256 principal);
```

In ERC4626 Vaults, `convertToAssetes` converts a given amount of shares into assets. In SimpleInterestVault, we have a similar `convertToAssetsAtPeriod` 
function that uses the Price to calculate the number of assets (Principal + Accrued Interest) for the given shares (Discounted Principal) at the time period.
```Solidity
/**
 * @notice Converts a given amount of shares to assets based on a specific time period.
 * @param sharesInWei The amount of shares to convert.
 * @param numTimePeriodsElapsed The number of time periods elapsed.
 * @return assetsInWei The number of assets corresponding to the shares at the specified time period.
 */
function convertToAssetsAtPeriod(uint256 sharesInWei, uint256 numTimePeriodsElapsed) public view returns (uint256 assetsInWei)
{
    uint256 impliedNumTimePeriodsAtDeposit = (numTimePeriodsElapsed - TENOR);

    uint256 _principal = calcPrincipalFromDiscounted(sharesInWei, impliedNumTimePeriodsAtDeposit);

    return _principal + calcInterest(_principal, TENOR);
}
```

