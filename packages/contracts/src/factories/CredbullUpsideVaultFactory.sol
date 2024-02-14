//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { ICredbull } from "../interface/ICredbull.sol";
import { CredbullVaultFactory } from "./CredbullVaultFactory.sol";
import { CredbullFixedYieldVaultWithUpside } from "../CredbullFixedYieldVaultWithUpside.sol";

contract CredbullUpsideVaultFactory is CredbullVaultFactory {
    constructor(address owner, address operator) CredbullVaultFactory(owner, operator) { }

    function createVault(ICredbull.VaultParams memory _params, uint256 _collateralPercentage)
        public
        onlyRole(OPERATOR_ROLE)
        onlyAllowedCustodians(_params.custodian)
        returns (address)
    {
        CredbullFixedYieldVaultWithUpside newVault =
            new CredbullFixedYieldVaultWithUpside(_params, _params.token, _collateralPercentage);

        emit VaultDeployed(address(newVault), _params);

        _addVault(address(newVault));

        return address(newVault);
    }
}
