// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import { ERC20Wrapper, ERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Wrapper.sol";
import { Ownable2Step, Ownable } from "@openzeppelin/contracts/access/Ownable2Step.sol";

/*
 * @title ERC20 Wrapper Token Contract
 */
contract CredbullERC20Wrapper is ERC20Wrapper, Ownable2Step {
    event CredbullERC20Wrapper__TokensRecovered(address indexed account, uint256 amount);

    struct Params {
        address owner;
        string name;
        string symbol;
        IERC20 underlyingToken;
    }

    constructor(Params memory params)
        ERC20Wrapper(params.underlyingToken)
        ERC20(params.name, params.symbol)
        Ownable(params.owner)
    { }

    /// @dev See {ERC20Wrapper-_recover}.
    function recover(address account) public virtual onlyOwner returns (uint256 _recoveredAmount) {
        _recoveredAmount = _recover(account);
        emit CredbullERC20Wrapper__TokensRecovered(account, _recoveredAmount);
    }
}
