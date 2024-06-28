//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { CredbullFixedYieldVault } from "./CredbullFixedYieldVault.sol";
import { VaultFactory } from "./factory/VaultFactory.sol";

contract CredbullFixedYieldVaultFactory is VaultFactory {
    /// @notice Event to emit when a new vault is created
    event VaultDeployed(address indexed vault, CredbullFixedYieldVault.FixedYieldVaultParams params, string options);

    /**
     * @param owner - The owner of the factory contract
     * @param operator - The operator of the factory contract
     * @param custodians - The custodians allowable for the vaults
     */
    constructor(address owner, address operator, address[] memory custodians)
        VaultFactory(owner, operator, custodians)
    { }

    /**
     * @notice - Function to create a new vault. Should be called only by the owner
     * @param params - The VaultParams
     */
    function createVault(CredbullFixedYieldVault.FixedYieldVaultParams memory params, string memory options)
        public
        virtual
        onlyRole(OPERATOR_ROLE)
        onlyAllowedCustodians(params.maturityVault.vault.custodian)
        returns (address)
    {
        CredbullFixedYieldVault newVault = new CredbullFixedYieldVault(params);

        emit VaultDeployed(address(newVault), params, options);

        _addVault(address(newVault));

        return address(newVault);
    }
}
