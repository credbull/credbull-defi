// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { TripleRateContext } from "@credbull/yield/context/TripleRateContext.sol";

contract TestTripleRateContext is TripleRateContext {
    constructor(
        uint256 fullRateScaled_,
        uint256 initialReducedRateScaled_,
        uint256 initialEffectiveFromPeriod_,
        uint256 frequency_,
        uint256 tenor_,
        uint256 decimals_
    )
        TripleRateContext(
            ContextParams({
                fullRateScaled: fullRateScaled_,
                initialReducedRate: PeriodRate({
                    interestRate: initialReducedRateScaled_,
                    effectiveFromPeriod: initialEffectiveFromPeriod_
                }),
                frequency: frequency_,
                tenor: tenor_,
                decimals: decimals_
            })
        )
    { }
}
