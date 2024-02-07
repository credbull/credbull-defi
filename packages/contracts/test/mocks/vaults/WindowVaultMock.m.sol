//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { CredbullBaseVault } from "../../../src/base/CredbullBaseVault.sol";
import { WindowPlugIn } from "../../../src/plugins/WindowPlug.sol";

contract WindowVaultMock is CredbullBaseVault, WindowPlugIn {
    constructor(VaultParams memory params)
        CredbullBaseVault(params)
        WindowPlugIn(params.depositOpensAt, params.depositClosesAt, params.redemptionOpensAt, params.redemptionClosesAt)
    { }

    modifier depositModifier(address receiver) override {
        _checkIsDepositWithinWindow();
        _;
    }

    modifier withdrawModifier() override {
        _checkIsWithdrawWithinWindow();
        _;
    }

    function toggleWindowCheck(bool status) public {
        _toggleWindowCheck(status);
    }
}
