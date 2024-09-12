// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

library Frequencies {
  error InvalidFrequency(Frequency frequency);

  enum Frequency {
    ANNUAL,
    MONTHLY,
    QUARTERLY,
    DAYS_360,
    DAYS_365
  }

  // Helper function to convert enum value to corresponding uint256 frequency
  function toValue(Frequency frequency) external pure returns (uint256) {
    if (frequency == Frequency.ANNUAL) return 1;
    if (frequency == Frequency.MONTHLY) return 12;
    if (frequency == Frequency.QUARTERLY) return 4;
    if (frequency == Frequency.DAYS_360) return 360;
    if (frequency == Frequency.DAYS_365) return 365;

    revert InvalidFrequency(frequency);
  }
}
