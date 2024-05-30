//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { CredbullBaseVault } from "../../../src/base/CredbullBaseVault.sol";
import { WindowPlugIn } from "../../../src/plugins/WindowPlugIn.sol";
import { ICredbull } from "../../../src/interface/ICredbull.sol";

contract WindowVaultMock is CredbullBaseVault, WindowPlugIn {
    constructor(CredbullBaseVault.BaseVaultParams memory params, WindowPlugIn.WindowVaultParams memory windowParams)
        CredbullBaseVault(params)
        WindowPlugIn(
            windowParams.depositWindow.opensAt,
            windowParams.depositWindow.closesAt,
            windowParams.matureWindow.opensAt,
            windowParams.matureWindow.closesAt
        )
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
