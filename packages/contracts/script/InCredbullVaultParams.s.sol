//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

import { Script } from "forge-std/Script.sol";
import { ICredbull } from "../src/interface/ICredbull.sol";

contract InCredbullVaultParams is Script {
    uint256 public constant ONE_YEAR = 365 days;
    uint256 public constant HALF_YEAR = 182 days;

    function create8APYParams(
        string memory shareSymbol,
        IERC20 asset,
        address owner,
        address operator,
        address custodian,
        uint256 opensAt
    ) public pure returns (ICredbull.VaultParams memory) {
        ICredbull.VaultParams memory vaultParams =
            createICVParams(shareSymbol, asset, owner, operator, custodian, 4, opensAt, HALF_YEAR);

        return vaultParams;
    }

    function create10APYParams(
        string memory shareSymbol,
        IERC20 asset,
        address owner,
        address operator,
        address custodian,
        uint256 opensAt
    ) public pure returns (ICredbull.VaultParams memory) {
        ICredbull.VaultParams memory vaultParams =
            createICVParams(shareSymbol, asset, owner, operator, custodian, 10, opensAt, ONE_YEAR);

        return vaultParams;
    }

    function createICVParams(
        string memory shareSymbol,
        IERC20 asset,
        address owner,
        address operator,
        address custodian,
        uint256 promisedYield,
        uint256 opensAt,
        uint256 redemptionOffset
    ) internal pure returns (ICredbull.VaultParams memory) {
        uint256 closesAt = opensAt + 14 days;

        ICredbull.VaultParams memory vaultParams = ICredbull.VaultParams({
            asset: asset,
            token: asset,
            shareName: "inCredbull Vault Claim",
            shareSymbol: shareSymbol,
            owner: owner,
            operator: operator,
            custodian: custodian,
            kycProvider: address(0),
            promisedYield: promisedYield,
            depositOpensAt: opensAt,
            depositClosesAt: closesAt,
            redemptionOpensAt: opensAt + redemptionOffset,
            redemptionClosesAt: closesAt + redemptionOffset,
            maxCap: 500000 * 1e6,
            depositThresholdForWhitelisting: 500001 * 1e6
        });

        return vaultParams;
    }
}
