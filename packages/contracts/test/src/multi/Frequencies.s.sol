// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

library Frequencies {
    enum Frequency {
        ONE_YEAR,
        DAYS_30,
        DAYS_180,
        DAYS_360
    }

    // Helper function to convert enum value to corresponding uint256 frequency
    function toValue(Frequency frequency) external pure returns (uint256) {
        if (frequency == Frequency.ONE_YEAR) return 1;
        if (frequency == Frequency.DAYS_30) return 30;
        if (frequency == Frequency.DAYS_180) return 180;
        if (frequency == Frequency.DAYS_360) return 360;
        revert("Invalid frequency");
    }
}
