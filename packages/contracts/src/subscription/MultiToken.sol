//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract CredbullSubscription is ERC1155 {
    constructor() ERC1155("testurl") { }

    function deposit(uint256 amount, address user) public {
        _mint(user, 0, amount, "");
    }
}
