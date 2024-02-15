//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract MaxCapPlugIn {
    error CredbullVault__MaxCapReached();

    //Max no.of assets that can be deposited to the vault;
    uint256 public maxCap;

    bool public checkMaxCap;

    constructor(uint256 _maxCap) {
        maxCap = _maxCap;
        checkMaxCap = true;
    }

    function _checkMaxCap(uint256 value) internal virtual {
        if (checkMaxCap && value > maxCap) {
            revert CredbullVault__MaxCapReached();
        }
    }

    function _toggleMaxCapCheck(bool status) internal virtual {
        checkMaxCap = status;
    }
}
