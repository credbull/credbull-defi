//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

abstract contract WindowPlugIn {
    //Error to revert when operation is outside required window
    error CredbullVault__OperationOutsideRequiredWindow(
        uint256 windowOpensAt, uint256 windowClosesAt, uint256 timestamp
    );

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

    bool public checkWindow;

    constructor(
        uint256 _depositOpensAt,
        uint256 _depositClosesAt,
        uint256 _redemptionOpensAt,
        uint256 _redemptionClosesAt
    ) {
        depositOpensAtTimestamp = _depositOpensAt;
        depositClosesAtTimestamp = _depositClosesAt;
        redemptionOpensAtTimestamp = _redemptionOpensAt;
        redemptionClosesAtTimestamp = _redemptionClosesAt;
        checkWindow = true;
    }

    function _checkIsWithinWindow(uint256 windowOpensAt, uint256 windowClosesAt) internal view {
        if (checkWindow && (block.timestamp < windowOpensAt || block.timestamp > windowClosesAt)) {
            revert CredbullVault__OperationOutsideRequiredWindow(windowOpensAt, windowClosesAt, block.timestamp);
        }
    }

    function _checkIsDepositWithinWindow() internal view virtual {
        _checkIsWithinWindow(depositOpensAtTimestamp, depositClosesAtTimestamp);
    }

    function _checkIsWithdrawWithinWindow() internal view virtual {
        _checkIsWithinWindow(redemptionOpensAtTimestamp, redemptionClosesAtTimestamp);
    }

    function _updateWindow(uint256 _depositOpen, uint256 _depositClose, uint256 _withdrawOpen, uint256 _withdrawClose)
        internal
        virtual
    {
        depositOpensAtTimestamp = _depositOpen;
        depositClosesAtTimestamp = _depositClose;
        redemptionOpensAtTimestamp = _withdrawOpen;
        redemptionClosesAtTimestamp = _withdrawClose;
    }

    function _toggleWindowCheck(bool status) internal {
        checkWindow = status;
    }
}
