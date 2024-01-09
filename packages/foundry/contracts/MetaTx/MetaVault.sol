//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {EIP712MetaTransaction} from './MetaTransaction.sol';
import {IERC20Permit} from '@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol';
import {console2} from "forge-std/console2.sol";

contract MetaVault is ERC4626, EIP712MetaTransaction {

    IERC20 usdt;

    constructor(string memory name, string memory symbol, IERC20 _asset) 
        ERC20(name, symbol)
        ERC4626(_asset)
        EIP712MetaTransaction("Cred", "1") {
            usdt = _asset;
        }

    function depositWithPermit(
        address sender,
        address receiver,
        uint256 assets,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns(uint256) {
        IERC20Permit(address(usdt)).permit(sender, address(this), assets, deadline, v, r, s);
        return deposit(assets, receiver);
    }

    function _msgSender() internal override view returns(address sender) {
        if(msg.sender == address(this)) {
            bytes memory array = msg.data;
            console2.logBytes(array);
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}