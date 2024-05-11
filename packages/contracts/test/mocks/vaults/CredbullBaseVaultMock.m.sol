//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { CredbullBaseVault } from "../../../src/base/CredbullBaseVault.sol";
import { ICredbull } from "../../../src/interface/ICredbull.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract CredbullBaseVaultMock is CredbullBaseVault {
    constructor(IERC20 asset, string memory shareName, string memory shareSymbol, address custodian)
        CredbullBaseVault(createVaultParams(asset, shareName, shareSymbol, custodian))
    { }

    function createVaultParams(IERC20 asset, string memory shareName, string memory shareSymbol, address custodian)
        internal
        pure
        returns (ICredbull.VaultParams memory)
    {
        ICredbull.VaultParams memory vaultParams = ICredbull.VaultParams({
            asset: asset,
            token: IERC20(address(0)),
            shareName: shareName,
            shareSymbol: shareSymbol,
            owner: address(0),
            operator: address(0),
            custodian: custodian,
            kycProvider: address(0),
            promisedYield: 0,
            depositOpensAt: 0,
            depositClosesAt: 0,
            redemptionOpensAt: 0,
            redemptionClosesAt: 0,
            maxCap: 0,
            depositThresholdForWhitelisting: 0
        });

        return vaultParams;
    }
}
