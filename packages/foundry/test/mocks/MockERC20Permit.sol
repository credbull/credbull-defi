//SPDX-License-Identifer: MIT

pragma solidity ^0.8.19;

import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20Permit is ERC20, ERC20Permit {
    constructor() ERC20("Mock 20", "mock") ERC20Permit("Mock 20") { }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
