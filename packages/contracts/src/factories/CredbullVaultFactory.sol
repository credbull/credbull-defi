//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { CredbullFixedYieldVault } from "../CredbullFixedYieldVault.sol";
import { ICredbull } from "../interface/ICredbull.sol";

/**
 * @notice - A factory contract to create vault contract
 */
contract CredbullVaultFactory is AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    error CredbullVault__CustodianNotAllowed();

    //Event to emit when a new vault is created
    event VaultDeployed(address indexed vault, ICredbull.VaultParams params, string options);

    //Address set that contains list of all vault address
    EnumerableSet.AddressSet internal allVaults;

    EnumerableSet.AddressSet internal allowedCustodians;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    constructor(address owner, address operator) {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(OPERATOR_ROLE, operator);
    }

    modifier onlyAllowedCustodians(address _custodian) virtual {
        if (!allowedCustodians.contains(_custodian)) {
            revert CredbullVault__CustodianNotAllowed();
        }

        _;
    }

    /**
     * @notice - Function to create a new vault. Can be called only by the owner
     * @param _params - The VaultParams
     */
    function createVault(ICredbull.VaultParams memory _params, string calldata _options)
        public
        virtual
        onlyRole(OPERATOR_ROLE)
        onlyAllowedCustodians(_params.custodian)
        returns (address)
    {
        CredbullFixedYieldVault newVault = new CredbullFixedYieldVault(_params);

        emit VaultDeployed(address(newVault), _params, _options);

        allVaults.add(address(newVault));

        return address(newVault);
    }

    function allowCustodian(address _custodian) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        return allowedCustodians.add(_custodian);
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
