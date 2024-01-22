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

    //Event to emit when a new vault is created
    event VaultDeployed(address indexed vault, address indexed asset, uint256 opensAt, uint256 closesAt);

    //Address set that contains list of all vault address
    EnumerableSet.AddressSet private allVaults;

    constructor(address owner) Ownable(owner) { }

    /**
     * @notice - Function to create a new vault. Can be called only by the owner
     * @param _params - The VaultParams
     */
    function createVault(ICredbull.VaultParams memory _params) public onlyOwner returns (CredbullVault newVault) {
        newVault = new CredbullVault(_params);

        emit VaultDeployed(address(newVault), newVault.asset(), _params.openAt, _params.closesAt);

        allVaults.add(address(newVault));
    }

    //Get total no.of vaults
    function getTotalVaultCount() external view returns (uint256) {
        return allVaults.length();
    }

    //Get vault address at a given index
    function getVaultAtIndex(uint256 _index) external view returns (address) {
        return allVaults.at(_index);
    }

    //Check if the vault exisits
    function isVaultExist(address _vault) external view returns (bool) {
        return allVaults.contains(_vault);
    }
}
