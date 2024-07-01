//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/// @notice - A PlugIn to handle MaxCap
abstract contract MaxCapPlugIn {
    error CredbullVault__MaxCapReached();

    /// @notice - Parameters for the MaxCap PlugIn
    struct MaxCapParams {
        uint256 maxCap;
    }

    /// @notice Max no.of assets that can be deposited to the vault;
    uint256 public maxCap;

    /// @notice Flag to check for max cap
    bool public checkMaxCap;

    constructor(uint256 _maxCap) {
        maxCap = _maxCap;
        checkMaxCap = true; // Set the check to true by default
    }

    /**
     * @notice - Function to check for max cap
     * @param value - The value to check against max cap
     */
    function _checkMaxCap(uint256 value) internal virtual {
        if (checkMaxCap && value > maxCap) {
            revert CredbullVault__MaxCapReached();
        }
    }

    /// @notice - Toggle the max cap check status
    function _toggleMaxCapCheck(bool status) internal virtual {
        checkMaxCap = status;
    }

    /// @notice - Update the max cap value
    function _updateMaxCap(uint256 _value) internal virtual {
        maxCap = _value;
    }
}
