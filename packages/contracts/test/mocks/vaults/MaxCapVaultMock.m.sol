//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { CredbullBaseVault } from "../../../src/base/CredbullBaseVault.sol";

import { MaxCapPlugIn } from "../../../src/plugins/MaxCapPlug.sol";

contract MaxCapVaultMock is CredbullBaseVault, MaxCapPlugIn {
    constructor(VaultParams memory params) CredbullBaseVault(params) MaxCapPlugIn(params.maxCap) { }

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
