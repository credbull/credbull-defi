// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

library Tenors {
    error InvalidFrequency(Tenor frequency);

    enum Tenor {
        ANNUAL,
        MONTHLY,
        QUARTERLY,
        DAYS_360,
        DAYS_365
    }

    // Helper function to convert enum value to corresponding uint256 frequency
    function toValue(Tenor tenor) external pure returns (uint256) {
        if (tenor == Tenor.ANNUAL) return 1;
        if (tenor == Tenor.MONTHLY) return 12;
        if (tenor == Tenor.QUARTERLY) return 4;
        if (tenor == Tenor.DAYS_360) return 360;
        if (tenor == Tenor.DAYS_365) return 365;

        revert InvalidFrequency(tenor);
    }
}
