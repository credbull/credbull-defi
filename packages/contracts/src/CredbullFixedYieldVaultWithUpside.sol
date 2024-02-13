// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { FixedYieldVault } from "./vaults/FixedYieldVault.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { UpsideVault } from "./vaults/UpsideVault.sol";

contract CredbullFixedYieldVaultWithUpside is UpsideVault {
    constructor(VaultParams memory params, IERC20 _token, uint256 _collateralPercentage)
        UpsideVault(params, _token, _collateralPercentage)
    { }
}
