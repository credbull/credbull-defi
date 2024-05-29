//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { ICredbull } from "../interface/ICredbull.sol";
import { CredbullFixedYieldVaultWithUpside } from "../CredbullFixedYieldVaultWithUpside.sol";
import { CredbullVaultFactory } from "./CredbullVaultFactory.sol";

contract CredbullUpsideVaultFactory is CredbullVaultFactory {
    /// @notice Event to emit when a new vault is created
    event VaultDeployed(
        address indexed vault, CredbullFixedYieldVaultWithUpside.UpsideVaultParams params, string options
    );

    /**
     * @param owner - The owner of the Factory contract
     * @param operator - The operator of the Factory contract
     */
    constructor(address owner, address operator) CredbullVaultFactory(owner, operator) { }

    /**
     * @notice - Function to create a new upside vault. Should be called only by the owner
     * @param _params - The VaultParams
     * @param options - A JSON string that contains additional info about vault (Off-chain use case)
     */
    function createVault(CredbullFixedYieldVaultWithUpside.UpsideVaultParams memory _params, string memory options)
        public
        onlyRole(OPERATOR_ROLE)
        onlyAllowedCustodians(_params.fixedYieldVaultParams.maturityVaultParams.baseVaultParams.custodian)
        returns (address)
    {
        CredbullFixedYieldVaultWithUpside newVault = new CredbullFixedYieldVaultWithUpside(_params);

        emit VaultDeployed(address(newVault), _params, options);

        _addVault(address(newVault));

        return address(newVault);
    }
}
