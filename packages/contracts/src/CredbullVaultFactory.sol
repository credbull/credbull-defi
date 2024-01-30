//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { CredbullVault } from "./CredbullVault.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { ICredbull } from "./interface/ICredbull.sol";

/**
 * @notice - A factory contract to create vault contract
 */
contract CredbullVaultFactory is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    //Error to revert on invalid entities data
    error CredbullVaultFactory__InvalidEntitiesData();
    //Error to revert if vault doens't exist on entities update
    error CredbullVaultFactory__VaultDoestExist(address);

    //Event to emit when a new vault is created
    event VaultDeployed(address indexed vault, ICredbull.VaultParams params);
    //Event to emit when entites are updated for a vault
    event UpdateEntities(address indexed vault, ICredbull.EntitiesData entities);

    //Address set that contains list of all vault address
    EnumerableSet.AddressSet private allVaults;

    //Mapping to stores entites data associated with vault
    mapping(address => ICredbull.EntitiesData) entities;

    constructor(address owner) Ownable(owner) { }

    /**
     * @notice - Function to create a new vault. Can be called only by the owner
     * @param _params - The VaultParams
     */
    function createVault(ICredbull.VaultParams memory _params) public onlyOwner returns (CredbullVault newVault) {
        newVault = new CredbullVault(_params);

        emit VaultDeployed(address(newVault), _params);

        allVaults.add(address(newVault));
    }

    //Get total no.of vaults
    function getTotalVaultCount() public view returns (uint256) {
        return allVaults.length();
    }

    //Get vault address at a given index
    function getVaultAtIndex(uint256 _index) public view returns (address) {
        return allVaults.at(_index);
    }

    //Check if the vault exisits
    function isVaultExist(address _vault) public view returns (bool) {
        return allVaults.contains(_vault);
    }

    //Create and update entities in single function
    function createVaultAndUpdateEntities(
        ICredbull.VaultParams memory _params,
        ICredbull.EntitiesData calldata _entitiesData
    ) public onlyOwner {
        CredbullVault vault = createVault(_params);
        updateEntitesData(address(vault), _entitiesData);
    }

    /**
     * @notice - Update the vault entities data
     * @dev - This update will just replace the exisiting data
     *
     * @param vault - The address of the vault for which the entities data to be updated
     * @param _entitiesData - The entities data
     */
    function updateEntitesData(address vault, ICredbull.EntitiesData calldata _entitiesData) public onlyOwner {
        if (_entitiesData.entities.length != _entitiesData.percentage.length) {
            revert CredbullVaultFactory__InvalidEntitiesData();
        }

        if (!(isVaultExist(vault))) {
            revert CredbullVaultFactory__VaultDoestExist(vault);
        }

        entities[vault] = _entitiesData;
        emit UpdateEntities(vault, _entitiesData);
    }

    /**
     * Returns the entites data for a given vault address
     * @param vault - Address of the vault
     */
    function getEntitiesData(address vault) external view returns (ICredbull.EntitiesData memory) {
        if (!(isVaultExist(vault))) {
            revert CredbullVaultFactory__VaultDoestExist(vault);
        }

        return entities[vault];
    }
}
