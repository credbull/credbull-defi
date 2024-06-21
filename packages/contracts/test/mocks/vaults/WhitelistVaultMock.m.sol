//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { CredbullBaseVault } from "../../../src/base/CredbullBaseVault.sol";
import { WhitelistPlugIn } from "../../../src/plugins/WhitelistPlugIn.sol";

contract WhitelistVaultMock is CredbullBaseVault, WhitelistPlugIn {
    constructor(CredbullBaseVault.BaseVaultParams memory params, WhitelistPlugIn.KycParams memory kycParams)
        CredbullBaseVault(params)
        WhitelistPlugIn(kycParams.kycProvider, kycParams.depositThresholdForWhitelisting)
    { }

    modifier depositModifier(address caller, address receiver, uint256 assets, uint256 shares) override {
        _checkIsWhitelisted(receiver, assets);
        _;
    }

    function toggleWhitelistCheck(bool status) public {
        _toggleWhitelistCheck(status);
    }
}
