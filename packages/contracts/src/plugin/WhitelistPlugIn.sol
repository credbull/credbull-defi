//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { IKYCProvider } from "../provider/kyc/IKYCProvider.sol";

/// @notice - A PlugIn to handle whitelisting
abstract contract WhitelistPlugIn {
    /// @notice If an invalid `IKYCProvider` Address is provided.
    error CredbullVault__InvalidKYCProviderAddress(address);
    /// @notice Error to revert if the address is not whitelisted
    error CredbullVault__NotAWhitelistedAddress(address, uint256);

    /// @notice - Parameters for the Whitelist PlugIn
    struct WhitelistPlugInParameters {
        address kycProvider;
        uint256 depositThresholdForWhitelisting;
    }

    /// @notice - Address of the Kyc provider
    IKYCProvider public kycProvider;

    /// @notice - Flag to check for whitelist
    bool public checkWhitelist;

    /// @notice - Deposit threshold amount to check for whitelisting
    uint256 public depositThresholdForWhitelisting;

    constructor(WhitelistPlugInParameters memory params) {
        if (params.kycProvider == address(0)) {
            revert CredbullVault__InvalidKYCProviderAddress(params.kycProvider);
        }

        kycProvider = IKYCProvider(params.kycProvider);
        checkWhitelist = true; // Set the check to true by default
        depositThresholdForWhitelisting = params.depositThresholdForWhitelisting;
    }

    /// @notice - Function to check for whitelisted address
    function _checkIsWhitelisted(address receiver, uint256 amount) internal view virtual {
        if (checkWhitelist && amount >= depositThresholdForWhitelisting && !kycProvider.status(receiver)) {
            revert CredbullVault__NotAWhitelistedAddress(receiver, amount);
        }
    }

    /// @notice - Function to toggle check for whitelisted address
    function _toggleWhitelistCheck(bool status) internal virtual {
        checkWhitelist = status;
    }
}
