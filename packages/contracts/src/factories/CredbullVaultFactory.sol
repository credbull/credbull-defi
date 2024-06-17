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

    /// @notice Error to revert if custodian is not allowed
    error CredbullVaultFactory__CustodianNotAllowed();

    /// @notice Event to emit when a new vault is created
    event VaultDeployed(address indexed vault, ICredbull.VaultParams params, string options);

    /// @notice Address set that contains list of all vault address
    EnumerableSet.AddressSet internal allVaults;

    /// @notice Address set that contains list of all custodian addresses
    EnumerableSet.AddressSet internal allowedCustodians;

    /// @notice Hash for operator role
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /**
     * @param owner - Owner of the factory contract
     * @param operator - Operator of the factory contract
     * @param custodians - Initial set of custodians allowable for the vaults
     */
    constructor(address owner, address operator, address[] memory custodians) {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(OPERATOR_ROLE, operator);

        // set the allowed custodians directly in the constructor, without access restriction
        bool[] memory result = new bool[](custodians.length);
        for (uint256 i = 0; i < custodians.length; i++) {
            result[i] = allowedCustodians.add(custodians[i]);
        }
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

    /// @notice Add vault address to the set
    function _addVault(address _vault) internal virtual {
        allVaults.add(_vault);
    }

    /// @notice Add custodian address to the set
    function allowCustodian(address _custodian) public onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        return allowedCustodians.add(_custodian);
    }

    /// @notice Remove custodian address from the set
    function removeCustodian(address _custodian) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (allowedCustodians.contains(_custodian)) {
            allowedCustodians.remove(_custodian);
        }
    }

    /// @notice Get total no.of vaults
    function getTotalVaultCount() public view returns (uint256) {
        return allVaults.length();
    }

    /// @notice Get vault address at a given index
    function getVaultAtIndex(uint256 _index) public view returns (address) {
        return allVaults.at(_index);
    }

    /// @notice Check if the vault exisits for a given address
    function isVaultExist(address _vault) public view returns (bool) {
        return allVaults.contains(_vault);
    }

    /// @notice Check if the custodian allowed for a given address
    function isCustodianAllowed(address _custodian) public view returns (bool) {
        return allowedCustodians.contains(_custodian);
    }
}
