//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { ICredbull } from "../interface/ICredbull.sol";
import { CredbullVaultFactory } from "./CredbullVaultFactory.sol";
import { CredbullFixedYieldVaultWithUpside } from "../CredbullFixedYieldVaultWithUpside.sol";

contract CredbullUpsideVaultFactory is CredbullVaultFactory {
    /**
     * @param owner - The owner of the Factory contract
     * @param operator - The operator of the Factory contract
     */
    constructor(address owner, address operator) CredbullVaultFactory(owner, operator) { }

    /**
     * @notice - Function to create a new upside vault. Should be called only by the owner
     * @param _params - The VaultParams
     * @param _collateralPercentage - The percentage of collateral to be deposited in Credbull Token
     * @param options - A JSON string that contains additional info about vault (Off-chain use case)
     */
    function createVault(ICredbull.VaultParams memory _params, uint256 _collateralPercentage, string memory options)
        public
        onlyRole(OPERATOR_ROLE)
        onlyAllowedCustodians(_params.custodian)
        returns (address)
    {
        CredbullFixedYieldVaultWithUpside newVault =
            new CredbullFixedYieldVaultWithUpside(_params, _params.token, _collateralPercentage);

        emit VaultDeployed(address(newVault), _params, options);

        _addVault(address(newVault));

        return address(newVault);
    }
}
