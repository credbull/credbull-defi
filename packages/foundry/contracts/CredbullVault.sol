// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Vaults exchange Assets for Shares in the Vault
// see: https://eips.ethereum.org/EIPS/eip-4626
contract CredbullVault is ERC4626, Ownable {
    constructor(
        address _owner,
        IERC20 _asset,
        string memory _shareName,
        string memory _shareSymbol
    )
    ERC4626(_asset)
    ERC20(_shareName, _shareSymbol)
    Ownable(_owner)
    {}
}
