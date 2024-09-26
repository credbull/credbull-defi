// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IYieldStrategy } from "@credbull/strategy/IYieldStrategy.sol";
import { MultipleRateYieldStrategy } from "@credbull/strategy/MultipleRateYieldStrategy.sol";
import { MultipleRateContext } from "@credbull/interest/context/MultipleRateContext.sol";

import { Frequencies } from "@test/src/interest/Frequencies.t.sol";

import { Test } from "forge-std/Test.sol";

contract MultipleRateYieldStrategyTest is Test {
    uint256 public constant TOLERANCE = 1; // with 6 decimals, diff of 0.000001
    uint256 public constant DECIMALS = 6;
    uint256 public constant SCALE = 10 ** DECIMALS;

    uint256 public constant PERCENT_5_SCALED = 5 * SCALE; // 5%
    uint256 public constant PERCENT_5_5_SCALED = 55 * SCALE / 10; // 5.5%
    uint256 public constant PERCENT_10_SCALED = 10 * SCALE; // 10%

    uint256 public constant DEFAULT_FULL_RATE = PERCENT_10_SCALED;
    uint256 public constant DEFAULT_REDUCED_RATE = PERCENT_5_SCALED;

    uint256 public constant MATURITY_PERIOD = 30;

    uint256 public immutable DEFAULT_FREQUENCY = Frequencies.toValue(Frequencies.Frequency.DAYS_365);

    IYieldStrategy internal yieldStrategy;
    MultipleRateContext internal context;
    address internal contextAddress;
    uint256 internal principal;
    uint256 internal depositPeriod;

    function setUp() public {
        yieldStrategy = new MultipleRateYieldStrategy();
        context = new MultipleRateContext(
            DEFAULT_FULL_RATE,
            DEFAULT_REDUCED_RATE,
            Frequencies.toValue(Frequencies.Frequency.DAYS_365),
            MATURITY_PERIOD,
            DECIMALS
        );
        contextAddress = address(context);
        principal = 1_000 * SCALE;
        depositPeriod = 1;
    }

    // TODO (JL,2024-09-26): Add tests.
}
