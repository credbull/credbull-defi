//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { CredbullBaseVault } from "../../../src/base/CredbullBaseVault.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract CredbullBaseVaultMock is CredbullBaseVault {
    constructor(IERC20 asset, string memory shareName, string memory shareSymbol, address custodian)
        CredbullBaseVault(createBaseVaultParams(asset, shareName, shareSymbol, custodian))
    { }

    function createBaseVaultParams(IERC20 asset, string memory shareName, string memory shareSymbol, address custodian)
        internal
        pure
        returns (BaseVaultParams memory vaultParams)
    {
        vaultParams =
            BaseVaultParams({ asset: asset, shareName: shareName, shareSymbol: shareSymbol, custodian: custodian });
    }
}
