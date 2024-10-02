// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { TripleRateContext } from "@credbull/yield/context/TripleRateContext.sol";

contract TestTripleRateContext is TripleRateContext {
    constructor(
        uint256 fullRateInPercentageScaled_,
        uint256 reducedRateInPercentageScaled_,
        uint256 frequency_,
        uint256 tenor_,
        uint256 decimals
    ) TripleRateContext(fullRateInPercentageScaled_, reducedRateInPercentageScaled_, frequency_, tenor_, decimals) { }
}
