//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/// @notice - A plugin to handle deposit and redemption windows
abstract contract WindowPlugin {
    /// @notice Error to revert when operation is outside required window
    error CredbullVault__OperationOutsideRequiredWindow(
        uint256 windowOpensAt, uint256 windowClosesAt, uint256 timestamp
    );

    /// @notice Error to revert when incorrect window values are provided
    error WindowPlugin__IncorrectWindowValues(
        uint256 depositOpen, uint256 depositClose, uint256 redeemOpen, uint256 redeemClose
    );

    /// @notice Event emitted when the window is updated
    event WindowUpdated(
        uint256 depositOpensAt, uint256 depositClosesAt, uint256 redemptionOpensAt, uint256 redemptionClosesAt
    );

    /// @notice Event emitted when the window check is updated
    event WindowCheckUpdated(bool indexed checkWindow);

    modifier validateWindows(uint256 _depositOpen, uint256 _depositClose, uint256 _redeemOpen, uint256 _redeemClose) {
        if (!(_depositOpen < _depositClose && _depositClose < _redeemOpen && _redeemOpen < _redeemClose)) {
            revert WindowPlugin__IncorrectWindowValues(_depositOpen, _depositClose, _redeemOpen, _redeemClose);
        }
        _;
    }

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

    constructor(WindowPluginParams memory params)
        validateWindows(
            params.depositWindow.opensAt,
            params.depositWindow.closesAt,
            params.redemptionWindow.opensAt,
            params.redemptionWindow.closesAt
        )
    {
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
        validateWindows(_depositOpen, _depositClose, _redeemOpen, _redeemClose)
    {
        depositOpensAtTimestamp = _depositOpen;
        depositClosesAtTimestamp = _depositClose;
        redemptionOpensAtTimestamp = _redeemOpen;
        redemptionClosesAtTimestamp = _redeemClose;

        emit WindowUpdated(_depositOpen, _depositClose, _redeemOpen, _redeemClose);
    }

    /// @notice - Function to toggle check for window
    function _toggleWindowCheck() internal {
        checkWindow = !checkWindow;
        emit WindowCheckUpdated(checkWindow);
    }
}
