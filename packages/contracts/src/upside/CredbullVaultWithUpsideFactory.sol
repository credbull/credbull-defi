//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { ICredbull } from "../interface/ICredbull.sol";
import { CredbullVaultFactory } from "../CredbullVaultFactory.sol";
import { CredbullFixedYieldLinkedVault } from "./CredbullFixedYieldLinkedVault.sol";
import { CredbullFixedYieldVaultWithUpside } from "./CredbullFixedYieldVaultWithUpside.sol";

contract CredbullVaultWithUpsideFactory is CredbullVaultFactory {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public requiredCollateral;

    event VaultStrategySet(address indexed vault, address indexed strategy);

    constructor(address owner, address operator, uint256 _requiredCollateral) CredbullVaultFactory(owner, operator) {
        requiredCollateral = _requiredCollateral;
    }

    function createVault(ICredbull.VaultParams memory _params, string calldata _options)
        public
        override
        onlyRole(OPERATOR_ROLE)
        returns (address)
    {
        ICredbull.VaultParams memory parentParams = ICredbull.VaultParams({
            asset: _params.token,
            token: _params.token,
            owner: _params.owner,
            operator: _params.operator,
            custodian: _params.custodian,
            kycProvider: _params.kycProvider,
            shareName: _params.shareName,
            shareSymbol: _params.shareSymbol,
            promisedYield: _params.promisedYield,
            depositOpensAt: _params.depositOpensAt,
            depositClosesAt: _params.depositClosesAt,
            redemptionOpensAt: _params.redemptionOpensAt,
            redemptionClosesAt: _params.redemptionClosesAt
        });
        CredbullFixedYieldVaultWithUpside strategy =
            new CredbullFixedYieldVaultWithUpside(parentParams, requiredCollateral);
        CredbullFixedYieldLinkedVault newVault = new CredbullFixedYieldLinkedVault(_params, address(strategy));

        strategy.setLinkedVault(address(newVault));
        strategy.transferOwnership(_params.operator);

        emit VaultDeployed(address(newVault), _params, _options);
        emit VaultStrategySet(address(newVault), address(strategy));

        allVaults.add(address(newVault));

        return address(newVault);
    }

    function setRequiredCollateral(uint256 _requiredCollateral) public onlyRole(DEFAULT_ADMIN_ROLE) {
        requiredCollateral = _requiredCollateral;
    }
}
