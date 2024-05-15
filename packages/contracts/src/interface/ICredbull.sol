//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

/**
 * @notice - Interface for all Credbull contracts.
 */
interface ICredbull {
    //Struct defining parameters for a vault
    struct VaultParams {
        address owner;
        address operator;
        IERC20 asset;
        IERC20 token;
        string shareName;
        string shareSymbol;
        uint256 promisedYield;
        uint256 depositOpensAt;
        uint256 depositClosesAt;
        uint256 redemptionOpensAt;
        uint256 redemptionClosesAt;
        address custodian;
        address kycProvider;
        uint256 maxCap;
        uint256 depositThresholdForWhitelisting;
    }

    struct BaseVaultParams {
        IERC20 asset;
        string shareName;
        string shareSymbol;
    }

    struct ContractRoles {
        address owner;
        address operator;
        address custodian;
    }

    struct WindowParams {
        uint256 opensAt;
        uint256 closesAt;
    }

    struct WindowVaultParams {
        WindowParams depositWindow;
        WindowParams matureWindow;
    }

    struct KycParams {
        address kycProvider;
        uint256 depositThresholdForWhitelisting;
    }

    struct MaxCapParams {
        uint256 maxCap;
    }

    struct FixedYieldVaultParams {
        BaseVaultParams baseVaultParams;
        ContractRoles contractRoles;
        WindowVaultParams windowVaultParams;
        KycParams kycParams;
        MaxCapParams maxCapParams;
        uint256 promisedYield;
    }

    struct MaturityVaultParams {
        BaseVaultParams baseVaultParams;
        ContractRoles contractRoles;
        WindowVaultParams windowVaultParams;
        KycParams kycParams;
        MaxCapParams maxCapParams;
        uint256 promisedYield;
    }

    /// @notice - Zero address error
    error ZeroAddress();
}
