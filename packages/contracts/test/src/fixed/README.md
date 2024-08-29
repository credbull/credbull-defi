# Simple Interest

**Simple Interest** is interest calculated only on the principal amount, excluding compounding. For more details, see [Wikipedia on Interest](https://en.wikipedia.org/wiki/Interest#Calculation).

### Formula

`Simple Interest = (IR * P * m) / f`

- **IR**: The simple annual interest rate
- **P**: The Principal (initial amount)
- **m**: The number of time periods elapsed
- **f**: The frequency of applying interest (number of interest periods in a year)

### Example
Imagine Alice invests $1,000 in a Credbull product that returns 12% annualized interest and matures in 30 days. The interest earned would be $10.

`Simple Interest = 0.12 * $1,000 * 30 / 360 = $10`

[Workbook with further Examples](https://docs.google.com/spreadsheets/d/1Uc6-JW8fJx6PcD_GxczW6EkvacxXuxjZhSDRqB0ZLcY/edit?gid=1548301220#gid=1548301220)

## Discounted Principal

**Discounted Principal** refers to the principal amount excluding interest accrued prior to my investment. This concept ensures that new investors do 
not receive credit for interest that was accrued before their investment was made.

### Formula
`Discounted Principal =  P - Interest[Prior]`
- **P**: The original Principal (initial amount).
- **Interest[Prior]**: interest that would have accrued if investing from the starting period

### Example
Now imagine Bob invests $1,000, but on day 2, in the Credbull 12% APY product with 30 day maturity.  In this case, Discounted Principal would be $999.67.

```
Discounted Principal = P - Interest[Prior] 
= $,1000 - (0.12 * $1,000 * 1 / 360) 
= $1,000 - $0.33 = $999.67
```

## Calculating Principal from Discounted Value

**Calculating the Principal from the Discounted Value** involves reversing the discounting process to recover the original principal amount. 

### Formula
To calculate the original Principal (P) from the Discounted Value (D), you use the following formula:

### Formula
`Principal = D + Interest[Prior]`

- **P**: The original Principal (initial amount).
- **D**: The Discounted Principal (Principal minus the accrued interest).
- **Interest[Prior]**: interest that would have accrued if investing from the starting period

### Relationship Between Principal and Discounted Factor

The **Discounted Factor** represents the reduction in the principal due to accrued interest over time. By applying the above formula, you can calculate the original principal from the discounted value, ensuring that the financial relationship between the initial investment and its adjusted value remains consistent.

### Example

Let's stick with Bob and our Credbull Product and the Discounted Principal of $999.67 from above.  In this case, Principal would be the expected $1,000.  

`P = Discounted Principal + Interest[Prior] = $999.67 + $0.33 = $1,000`

## Inverse Relationship Between Discounted and Principal

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

----

