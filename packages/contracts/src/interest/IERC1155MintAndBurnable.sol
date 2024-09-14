// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC1155 } from "@openzeppelin/contracts/interfaces/IERC1155.sol";

interface IERC1155MintAndBurnable is IERC1155 {
    function mint(address to, uint256 id, uint256 value, bytes memory data) external;

    function burn(address from, uint256 id, uint256 value) external;
}
