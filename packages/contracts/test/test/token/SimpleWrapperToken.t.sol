// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Wrapper } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Wrapper.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

/*
 * @title ERC20 Wrapper Token Contract
 & @dev - this is non-upgradeable.  alternatively extend "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20WrapperUpgradeable.sol"
 */
contract SimpleWrapperToken is ERC20Wrapper, AccessControl {
    /// @dev Error to indicate that the provided owner address is invalid.
    error SimpleWrapperToken__InvalidOwnerAddress();

    struct SimpleWrapperTokenParams {
        address owner;
        string name;
        string symbol;
        IERC20 underlyingToken;
    }

    constructor(SimpleWrapperTokenParams memory params)
        ERC20Wrapper(params.underlyingToken)
        ERC20(params.name, params.symbol)
    {
        if (params.owner == address(0)) {
            revert SimpleWrapperToken__InvalidOwnerAddress();
        }

        _grantRole(DEFAULT_ADMIN_ROLE, params.owner);
    }
}
