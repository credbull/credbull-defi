//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { IERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import { ERC2771Context } from "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import { ERC2771Forwarder } from "@openzeppelin/contracts/metatx/ERC2771Forwarder.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";

contract MetaVault is ERC4626, ERC2771Context {
    constructor(string memory name, string memory symbol, IERC20 _asset, ERC2771Forwarder forwarder)
        ERC20(name, symbol)
        ERC4626(_asset)
        ERC2771Context(address(forwarder))
    { }

    function depositWithPermit(
        address sender,
        address receiver,
        uint256 assets,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256) {
        IERC20Permit(address(this.asset())).permit(sender, address(this), assets, deadline, v, r, s);
        return deposit(assets, receiver);
    }

    function _msgSender() internal view virtual override(Context, ERC2771Context) returns (address sender) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }

    function _contextSuffixLength() internal view override(Context, ERC2771Context) returns (uint256) {
        return ERC2771Context._contextSuffixLength();
    }
}
