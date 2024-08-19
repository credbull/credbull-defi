// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

library Tenors {
    error InvalidFrequency(Tenor frequency);

    enum Tenor {
        YEARS_ONE,
        YEARS_TWO,
        DAYS_30,
        DAYS_180,
        DAYS_360
    }

    // Helper function to convert enum value to corresponding uint256 frequency
    function toValue(Tenor tenor) external pure returns (uint256) {
        if (tenor == Tenor.YEARS_ONE) return 1;
        if (tenor == Tenor.YEARS_TWO) return 1;
        if (tenor == Tenor.DAYS_30) return 30;
        if (tenor == Tenor.DAYS_180) return 180;
        if (tenor == Tenor.DAYS_360) return 360;

        revert InvalidFrequency(tenor);
    }
}
