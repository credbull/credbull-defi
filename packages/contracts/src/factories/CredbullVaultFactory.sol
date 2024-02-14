//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ICredbull } from "../interface/ICredbull.sol";

/**
 * @notice - A factory contract to create vault contract
 */
abstract contract CredbullVaultFactory is AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    //Error to revert if custodian is not allowed
    error CredbullVaultFactory__CustodianNotAllowed();

    //Event to emit when a new vault is created
    event VaultDeployed(address indexed vault, ICredbull.VaultParams params);

    //Address set that contains list of all vault address
    EnumerableSet.AddressSet internal allVaults;

    //Address set that contains list of all custodian addresses
    EnumerableSet.AddressSet internal allowedCustodians;

    //Hash for operator role
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /**
     *
     * @param owner - Owner of the factory contract
     * @param operator - Operator of the factory contract
     */
    constructor(address owner, address operator) {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(OPERATOR_ROLE, operator);
    }

    /**
     * Modifier to check for valid custodian address
     *
     * @param _custodian - The custodian address
     */
    modifier onlyAllowedCustodians(address _custodian) virtual {
        if (!allowedCustodians.contains(_custodian)) {
            revert CredbullVaultFactory__CustodianNotAllowed();
        }

        _;
    }

    //Add vault address to the set
    function _addVault(address _vault) internal virtual {
        allVaults.add(_vault);
    }

    //Add custodian address to the set
    function allowCustodian(address _custodian) public onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        return allowedCustodians.add(_custodian);
    }

    //Remove custodian address from the set
    function removeCustodian(address _custodian) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (allowedCustodians.contains(_custodian)) {
            allowedCustodians.remove(_custodian);
        }
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

    function isCustodianAllowed(address _custodian) public view returns (bool) {
        return allowedCustodians.contains(_custodian);
    }
}
