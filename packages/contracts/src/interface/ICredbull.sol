//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

/**
 * @notice - abstract contract representing the interface for Credbull contracts.
 */
abstract contract ICredbull {
    //Struct defining parameters for a vault
    struct VaultParams {
        address owner;
        IERC20 asset;
        string shareName;
        string shareSymbol;
        uint256 promisedYield;
        uint256 openAt;
        uint256 closesAt;
        address custodian;
        address kycProvider;
        address treasury;
        address activityReward;
    }

    //Struct defining various entities associated with Credbull
    struct Entities {
        address kycProvider;
        address treasury;
        address activityReward;
        address custodian;
    }
}
