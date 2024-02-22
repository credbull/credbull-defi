//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { CredbullVaultFactory } from "./CredbullVaultFactory.sol";
import { ICredbull } from "../interface/ICredbull.sol";
import { CredbullFixedYieldVault } from "../CredbullFixedYieldVault.sol";

contract CredbullFixedYieldVaultFactory is CredbullVaultFactory {
    /**
     * @param owner - The owner of the factory contract
     * @param operator - The operator of the factory contract
     */
    constructor(address owner, address operator) CredbullVaultFactory(owner, operator) { }

    /**
     * @notice - Function to create a new vault. Should be called only by the owner
     * @param _params - The VaultParams
     */
    function createVault(ICredbull.VaultParams memory _params, string memory options)
        public
        virtual
        onlyRole(OPERATOR_ROLE)
        onlyAllowedCustodians(_params.custodian)
        returns (address)
    {
        CredbullFixedYieldVault newVault = new CredbullFixedYieldVault(_params);

        emit VaultDeployed(address(newVault), _params, options);

        _addVault(address(newVault));

        return address(newVault);
    }
}
