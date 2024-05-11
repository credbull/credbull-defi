//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { CredbullBaseVault } from "../../../src/base/CredbullBaseVault.sol";
import { ICredbull } from "../../../src/interface/ICredbull.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract CredbullBaseVaultMock is CredbullBaseVault {
    //    struct VaultParams {
    //        address owner;
    //        address operator;
    //        IERC20 asset;
    //        IERC20 token;
    //        string shareName;
    //        string shareSymbol;
    //        uint256 promisedYield;
    //        uint256 depositOpensAt;
    //        uint256 depositClosesAt;
    //        uint256 redemptionOpensAt;
    //        uint256 redemptionClosesAt;
    //        address custodian;
    //        address kycProvider;
    //        uint256 maxCap;
    //        uint256 depositThresholdForWhitelisting;
    //    }

    constructor(IERC20 asset, string memory shareName, string memory shareSymbol, address custodian)
        CredbullBaseVault(createVaultParams(asset, shareName, shareSymbol, custodian))
    { }

    function createVaultParams(IERC20 asset, string memory shareName, string memory shareSymbol, address custodian)
        internal
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
