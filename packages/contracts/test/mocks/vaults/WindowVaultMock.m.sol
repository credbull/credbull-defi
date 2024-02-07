//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { CredbullBaseVault } from "../../../src/base/CredbullBaseVault.sol";
import { WindowPlugIn } from "../../../src/plugins/WindowPlugIn.sol";

contract WindowVaultMock is CredbullBaseVault, WindowPlugIn {
    constructor(VaultParams memory params)
        CredbullBaseVault(params)
        WindowPlugIn(params.depositOpensAt, params.depositClosesAt, params.redemptionOpensAt, params.redemptionClosesAt)
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

    function toggleWindowCheck(bool status) public {
        _toggleWindowCheck(status);
    }
}
