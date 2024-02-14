// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { UpsideVault } from "./vaults/UpsideVault.sol";

contract CredbullFixedYieldVaultWithUpside is UpsideVault {
    constructor(VaultParams memory params, IERC20 _token, uint256 _collateralPercentage)
        UpsideVault(params, _token, _collateralPercentage)
    { }
}
