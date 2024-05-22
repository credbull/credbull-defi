//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { ICredbull } from "../interface/ICredbull.sol";
import { CredbullFixedYieldVault } from "../CredbullFixedYieldVault.sol";
import { CredbullVaultFactory } from "./CredbullVaultFactory.sol";

contract CredbullFixedYieldVaultFactory is CredbullVaultFactory {
    /// @notice Event to emit when a new vault is created
    event VaultDeployed(address indexed vault, ICredbull.FixedYieldVaultParams params, string options);
    /**
     * @param owner - The owner of the factory contract
     * @param operator - The operator of the factory contract
     */

    constructor(address owner, address operator) CredbullVaultFactory(owner, operator) { }

    /**
     * @notice - Function to create a new vault. Should be called only by the owner
     * @param _params - The VaultParams
     */
    function createVault(ICredbull.FixedYieldVaultParams memory _params, string memory options)
        public
        virtual
        onlyRole(OPERATOR_ROLE)
        onlyAllowedCustodians(_params.baseVaultParams.custodian)
        returns (address)
    {
        CredbullFixedYieldVault newVault = new CredbullFixedYieldVault(_params);

        emit VaultDeployed(address(newVault), _params, options);

        _addVault(address(newVault));

        return address(newVault);
    }
}
