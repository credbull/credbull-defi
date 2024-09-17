// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC1155MintAndBurnable } from "@credbull/interest/IERC1155MintAndBurnable.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract SimpleIERC1155Mintable is ERC1155, IERC1155MintAndBurnable {
    constructor() ERC1155("") { }

    function mint(address to, uint256 id, uint256 value, bytes memory data) public override {
        _mint(to, id, value, data);
    }

    function burn(address from, uint256 id, uint256 value) public override {
        _burn(from, id, value);
    }
}
