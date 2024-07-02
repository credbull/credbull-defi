//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/// @notice - A plugin to handle deposit and redemption windows
abstract contract WindowPlugin {
    /// @notice Error to revert when operation is outside required window
    error CredbullVault__OperationOutsideRequiredWindow(
        uint256 windowOpensAt, uint256 windowClosesAt, uint256 timestamp
    );

    /// @notice A Window is essentially a Time Span, denoted by an Opening and Closing Time pair.
    struct Window {
        uint256 opensAt;
        uint256 closesAt;
    }

    /// @notice - Struct to hold window parameters
    struct WindowPluginParams {
        Window depositWindow;
        Window redemptionWindow;
    }

    /// @dev The timestamp when the vault opens for deposit.
    uint256 public depositOpensAtTimestamp;

    /// @dev The timestamp when the vault closes for deposit.
    uint256 public depositClosesAtTimestamp;

    /// @dev The timestamp when the vault opens for redemption.
    uint256 public redemptionOpensAtTimestamp;

    /// @dev The timestamp when the vault closes for redemption.
    uint256 public redemptionClosesAtTimestamp;

    /// @notice - Flag to check for window
    bool public checkWindow;

    constructor(WindowPluginParams memory params) {
        depositOpensAtTimestamp = params.depositWindow.opensAt;
        depositClosesAtTimestamp = params.depositWindow.closesAt;
        redemptionOpensAtTimestamp = params.redemptionWindow.opensAt;
        redemptionClosesAtTimestamp = params.redemptionWindow.closesAt;
        checkWindow = true;
    }

    /// @notice Check if a given timestamp is with in a window
    /// @dev NOTE (JL,2024-07-01): Could we call this '_assertWindow' instead?
    function _checkIsWithinWindow(uint256 windowOpensAt, uint256 windowClosesAt) internal view {
        if (checkWindow && (block.timestamp < windowOpensAt || block.timestamp > windowClosesAt)) {
            revert CredbullVault__OperationOutsideRequiredWindow(windowOpensAt, windowClosesAt, block.timestamp);
        }
    }

    /// @notice Check for deposit window
    function _checkIsDepositWithinWindow() internal view virtual {
        _checkIsWithinWindow(depositOpensAtTimestamp, depositClosesAtTimestamp);
    }

    /// @notice Check for redemption window
    function _checkIsRedeemWithinWindow() internal view virtual {
        _checkIsWithinWindow(redemptionOpensAtTimestamp, redemptionClosesAtTimestamp);
    }

    /// @notice - Function to update all timestamps
    /// @dev NOTE (JL,2024-07-01): Why does this not use 2x `Window` instances or a `WindowPluginParams`?
    ///  That is their purpose.
    function _updateWindow(uint256 _depositOpen, uint256 _depositClose, uint256 _redeemOpen, uint256 _redeemClose)
        internal
        virtual
    {
        depositOpensAtTimestamp = _depositOpen;
        depositClosesAtTimestamp = _depositClose;
        redemptionOpensAtTimestamp = _redeemOpen;
        redemptionClosesAtTimestamp = _redeemClose;
    }

    /// @notice - Function to toggle check for window
    function _toggleWindowCheck(bool status) internal {
        checkWindow = status;
    }
}
