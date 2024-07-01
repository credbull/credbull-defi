//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { CredbullBaseVault } from "../../../src/base/CredbullBaseVault.sol";

import { MaxCapPlugIn } from "../../../src/plugins/MaxCapPlugIn.sol";
import { CredbullBaseVault } from "../../../src/base/CredbullBaseVault.sol";

contract MaxCapVaultMock is CredbullBaseVault, MaxCapPlugIn {
    constructor(CredbullBaseVault.BaseVaultParams memory params, MaxCapPlugIn.MaxCapParams memory maxCapParams)
        CredbullBaseVault(params)
        MaxCapPlugIn(maxCapParams.maxCap)
    { }

    modifier depositModifier(address caller, address receiver, uint256 assets, uint256 shares) override {
        _checkMaxCap(totalAssetDeposited + assets);
        _;
    }

    function toggleMaxCapCheck(bool status) public {
        _toggleMaxCapCheck(status);
    }

    function updateMaxCap(uint256 _value) public {
        _updateMaxCap(_value);
    }
}
