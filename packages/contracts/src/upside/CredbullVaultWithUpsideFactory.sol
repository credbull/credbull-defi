//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { ICredbull } from "../interface/ICredbull.sol";
import { CredbullVaultFactory } from "../CredbullVaultFactory.sol";
import { CredbullFixedYieldVaultWithUpside } from "./CredbullFixedYieldVaultWithUpside.sol";

contract CredbullVaultWithUpsideFactory is CredbullVaultFactory {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public requiredCollateral;

    constructor(address owner, address operator, uint256 _requiredCollateral) CredbullVaultFactory(owner, operator) {
        requiredCollateral = _requiredCollateral;
    }

    function createVault(ICredbull.VaultParams memory _params, string calldata _options)
        public
        override
        onlyRole(OPERATOR_ROLE)
        onlyAllowedCustodians(_params.custodian)
        returns (address)
    {
        if (!allowedCustodians.contains(_params.custodian)) {
            revert CredbullVault__CustodianNotAllowed();
        }

        CredbullFixedYieldVaultWithUpside newVault =
            new CredbullFixedYieldVaultWithUpside(_params, _params.token, requiredCollateral);

        emit VaultDeployed(address(newVault), _params, _options);

        allVaults.add(address(newVault));

        return address(newVault);
    }

    function setRequiredCollateral(uint256 _requiredCollateral) public onlyRole(DEFAULT_ADMIN_ROLE) {
        requiredCollateral = _requiredCollateral;
    }
}
