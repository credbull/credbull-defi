//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { IKYCProvider } from "../interface/IKYCProvider.sol";
import { ICredbull } from "../interface/ICredbull.sol";

/// @notice - A PlugIn to handle whitelisting
abstract contract WhitelistPlugIn {
    /// @notice Error to revert if the address is not whitelisted
    error CredbullVault__NotAWhitelistedAddress(address, uint256);

    /// @notice - Parameters for the Whitelist PlugIn
    struct KycParams {
        address kycProvider;
        uint256 depositThresholdForWhitelisting;
    }

    /// @notice - Address of the Kyc provider
    IKYCProvider public kycProvider;

    /// @notice - Flag to check for whitelist
    bool public checkWhitelist;

    /// @notice - Deposit threshold amount to check for whitelisting
    uint256 public depositThresholdForWhitelisting;

    /**
     * @param _kycProvider - Address of the Kyc Provider
     */
    constructor(address _kycProvider, uint256 _depositThresholdForWhitelisting) {
        if (_kycProvider == address(0)) {
            revert ICredbull.ZeroAddress();
        }

        kycProvider = IKYCProvider(_kycProvider);
        checkWhitelist = true; // Set the check to true by default
        depositThresholdForWhitelisting = _depositThresholdForWhitelisting;
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
