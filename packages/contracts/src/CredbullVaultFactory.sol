//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { CredbullVault } from "./CredbullVault.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract CredbullVaultFactory is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private allVaults;

    constructor() Ownable(msg.sender) { }

    struct VaultParams {
        address owner;
        IERC20 asset;
        string shareName;
        string shareSymbol;
        uint256 promisedYield;
        uint256 openAt;
        uint256 closesAt;
        address custodian;
    }

    function createVault(VaultParams calldata _params) public onlyOwner returns (CredbullVault newVault) {
        newVault = new CredbullVault(
            _params.owner,
            _params.asset,
            _params.shareName,
            _params.shareSymbol,
            _params.promisedYield,
            _params.openAt,
            _params.closesAt,
            _params.custodian
        );

        allVaults.add(address(newVault));
    }

    function getTotalVaultCount() external view returns (uint256) {
        return allVaults.length();
    }

    function getVaultAtIndex(uint256 _index) external view returns (address) {
        return allVaults.at(_index);
    }

    function isVaultExist(address _vault) external view returns (bool) {
        return allVaults.contains(_vault);
    }
}
