//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Vault } from "@src/vault/Vault.sol";
import { WindowPlugIn } from "@src/plugin/WindowPlugIn.sol";

contract MockWindowVault is Vault, WindowPlugIn {
    constructor(VaultParameters memory params, WindowPlugInParameters memory windowPlugInParams)
        Vault(params)
        WindowPlugIn(windowPlugInParams)
    { }

    modifier depositModifier(address caller, address receiver, uint256 assets, uint256 shares) override {
        _checkIsDepositWithinWindow();
        _;
    }

    modifier withdrawModifier(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        override
    {
        _checkIsWithdrawWithinWindow();
        _;
    }

    function updateWindow(uint256 _depositOpen, uint256 _depositClose, uint256 _withdrawOpen, uint256 _withdrawClose)
        public
    {
        _updateWindow(_depositOpen, _depositClose, _withdrawOpen, _withdrawClose);
    }

    function toggleWindowCheck(bool status) public {
        _toggleWindowCheck(status);
    }
}
