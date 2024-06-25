//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IErrors {
    error CredbullVault__InvalidCustodianAddress(address);
    error CredbullVault__InvalidAsset(IERC20);
}
