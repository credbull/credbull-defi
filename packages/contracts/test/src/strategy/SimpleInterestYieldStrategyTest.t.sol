// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IYieldStrategy } from "@credbull/strategy/IYieldStrategy.sol";
import { SimpleInterestYieldStrategy } from "@credbull/strategy/SimpleInterestYieldStrategy.sol";
import { CalcInterestMetadata } from "@credbull/interest/CalcInterestMetadata.sol";

import { Frequencies } from "@test/src/interest/Frequencies.t.sol";

import { Test } from "forge-std/Test.sol";

contract SimpleInterestYieldStrategyTest is Test {
    uint256 public constant TOLERANCE = 1; // with 6 decimals, diff of 0.000001

    uint256 public constant DECIMALS = 6;
    uint256 public constant SCALE = 10 ** DECIMALS;

    function test__SimpleInterestYieldStrategy__CalculateYield() public {
        uint256 apy = 6 * SCALE; // APY in percentage
        uint256 frequency = Frequencies.toValue(Frequencies.Frequency.DAYS_360);

        IYieldStrategy yieldStrategy = new SimpleInterestYieldStrategy();
        address interestContractAddress = address(new CalcInterestMetadataMock(apy, frequency, DECIMALS));

        uint256 principal = 500 * SCALE;

        assertApproxEqAbs(
            83_333,
            yieldStrategy.calcYield(interestContractAddress, principal, 0, 1),
            TOLERANCE,
            "yield wrong at period 0 to 1"
        );
        assertApproxEqAbs(
            166_666,
            yieldStrategy.calcYield(interestContractAddress, principal, 1, 3),
            TOLERANCE,
            "yield wrong at period 1 to 3"
        );
        assertApproxEqAbs(
            2_500_000,
            yieldStrategy.calcYield(interestContractAddress, principal, 1, 31),
            TOLERANCE,
            "yield wrong at period 1 to 31"
        );

        address interest2Addr = address(new CalcInterestMetadataMock(apy * 2, frequency, DECIMALS)); // double the interest rate
        assertApproxEqAbs(
            5_000_000, // yield should also double
            yieldStrategy.calcYield(interest2Addr, principal, 1, 31),
            TOLERANCE,
            "yield wrong at period 1 to 31 - double APY"
        );
    }

    function test__SimpleInterestYieldStrategy__CalculatePrice() public {
        uint256 apy = 12 * SCALE;
        uint256 frequency = Frequencies.toValue(Frequencies.Frequency.DAYS_360);

        IYieldStrategy yieldStrategy = new SimpleInterestYieldStrategy();
        address interestContractAddress = address(new CalcInterestMetadataMock(apy, frequency, DECIMALS));

        assertEq(1 * SCALE, yieldStrategy.calcPrice(interestContractAddress, 0), "price wrong at period 0"); // 1 + (0.12 * 0) / 360 = 1
        assertEq(1_000_333, yieldStrategy.calcPrice(interestContractAddress, 1), "price wrong at period 1"); // 1 + (0.12 * 1) / 360 ≈ 1.00033
        assertEq((101 * SCALE / 100), yieldStrategy.calcPrice(interestContractAddress, 30), "price wrong at period 30"); // 1 + (0.12 * 30) / 360 = 1.01
    }
}

contract CalcInterestMetadataMock is CalcInterestMetadata {
    constructor(uint256 interestRatePercentage, uint256 frequency, uint256 decimals)
        CalcInterestMetadata(interestRatePercentage, frequency, decimals)
    { }
}
