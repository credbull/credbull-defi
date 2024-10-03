// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { TripleRateContext } from "@credbull/yield/context/TripleRateContext.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract TestTripleRateContext is Initializable, UUPSUpgradeable, TripleRateContext {
    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal virtual override { }

    function __TestTripeRateContext_init(
        uint256 fullRateScaled_,
        uint256 initialReducedRateScaled_,
        uint256 initialEffectiveFromPeriod_,
        uint256 frequency_,
        uint256 tenor_,
        uint256 decimals_
    ) public initializer {
        __TripleRateContext_init(
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
        );
    }
}
