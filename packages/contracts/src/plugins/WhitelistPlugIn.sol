//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { AKYCProvider } from "../../test/mocks/MockKYCProvider.sol";

/// @notice - A PlugIn to handle whitelisting
abstract contract WhitelistPlugIn {
    /// @notice Error to revert if the address is not whitelisted
    error CredbullVault__NotAWhitelistedAddress();

    /// @notice - Address of the Kyc provider
    AKYCProvider public kycProvider;

    /// @notice - Flag to check for whitelist
    bool public checkWhitelist;

    /**
     * @param _kycProvider - Address of the Kyc Provider
     */
    constructor(address _kycProvider) {
        kycProvider = AKYCProvider(_kycProvider);
        checkWhitelist = true; // Set the check to true by default
    }

    /// @notice - Function to check for whitelisted address
    function _checkIsWhitelisted(address receiver) internal view virtual {
        if (checkWhitelist && !kycProvider.status(receiver)) {
            revert CredbullVault__NotAWhitelistedAddress();
        }
    }

    /// @notice - Function to toggle check for whitelisted address
    function _toggleWhitelistCheck(bool status) internal virtual {
        checkWhitelist = status;
    }
}
