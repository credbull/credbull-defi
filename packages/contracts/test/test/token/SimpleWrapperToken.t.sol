// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Wrapper } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Wrapper.sol";
// import { ERC20WrapperUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20WrapperUpgradeable.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

/*
 * @title SimpleWrapperTokenV1 Token Contract
 * @dev ERC20 token with additional features: permit, burnable, capped supply and access control.
 */
contract SimpleWrapperToken is ERC20Wrapper, AccessControl {
    /// @dev Error to indicate that the provided owner address is invalid.
    error SimpleWrapperToken__InvalidOwnerAddress();

    constructor(IERC20 underlyingToken, address _owner)
        ERC20Wrapper(underlyingToken)
        ERC20("SimpleWrapperTokenV1", "SimpleWrapperTokenV1")
    {
        if (_owner == address(0)) {
            revert SimpleWrapperToken__InvalidOwnerAddress();
        }

        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
    }
}
