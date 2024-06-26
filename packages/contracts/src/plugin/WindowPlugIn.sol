//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/// @notice - A plugIn to handle deposit and withdraw window
abstract contract WindowPlugIn {
    /// @notice Error to revert when operation is outside required window
    error CredbullVault__OperationOutsideRequiredWindow(
        uint256 windowOpensAt, uint256 windowClosesAt, uint256 timestamp
    );

    /// @notice A Window is essentially a Time Span, with an Opening and Closing Time pair.
    struct Window {
        uint256 opensAt;
        uint256 closesAt;
    }

    /// @notice - Struct to hold window parameters
    struct WindowPlugInParameters {
        Window depositWindow;
        Window redemptionWindow;
    }

    /**
     * @dev
     * The timestamp when the vault opens for deposit.
     */
    uint256 public depositOpensAtTimestamp;

    /**
     * @dev
     * The timestamp when the vault closes for deposit.
     */
    uint256 public depositClosesAtTimestamp;

    /**
     * @dev
     * The timestamp when the vault opens for redemption.
     */
    uint256 public redemptionOpensAtTimestamp;

    /**
     * @dev
     * The timestamp when the vault closes for redemption.
     */
    uint256 public redemptionClosesAtTimestamp;

    /// @notice - Flag to check for window
    bool public checkWindow;

    constructor(WindowPlugInParameters memory params) {
        depositOpensAtTimestamp = params.depositWindow.opensAt;
        depositClosesAtTimestamp = params.depositWindow.closesAt;
        redemptionOpensAtTimestamp = params.redemptionWindow.opensAt;
        redemptionClosesAtTimestamp = params.redemptionWindow.closesAt;
        checkWindow = true;
    }

    /// @notice - Check if a given timestamp is with in a window
    function _checkIsWithinWindow(uint256 windowOpensAt, uint256 windowClosesAt) internal view {
        if (checkWindow && (block.timestamp < windowOpensAt || block.timestamp > windowClosesAt)) {
            revert CredbullVault__OperationOutsideRequiredWindow(windowOpensAt, windowClosesAt, block.timestamp);
        }
    }

    /// @notice - Check for deposit window
    function _checkIsDepositWithinWindow() internal view virtual {
        _checkIsWithinWindow(depositOpensAtTimestamp, depositClosesAtTimestamp);
    }

    /// @notice Check for withdraw window
    function _checkIsWithdrawWithinWindow() internal view virtual {
        _checkIsWithinWindow(redemptionOpensAtTimestamp, redemptionClosesAtTimestamp);
    }

    /// @notice - Function to update all timestamps
    function _updateWindow(uint256 _depositOpen, uint256 _depositClose, uint256 _withdrawOpen, uint256 _withdrawClose)
        internal
        virtual
    {
        depositOpensAtTimestamp = _depositOpen;
        depositClosesAtTimestamp = _depositClose;
        redemptionOpensAtTimestamp = _withdrawOpen;
        redemptionClosesAtTimestamp = _withdrawClose;
    }

    /// @notice - Function to toggle check for window
    function _toggleWindowCheck(bool status) internal {
        checkWindow = status;
    }
}
