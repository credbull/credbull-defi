// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { SimpleInterestVault } from "./SimpleInterestVault.s.sol";
import { TimelockIERC1155 } from "../timelock/TimelockIERC1155.s.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC1155Supply } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract TimelockInterestVault is TimelockIERC1155, SimpleInterestVault {
    constructor(address initialOwner, IERC20 asset, uint256 interestRatePercentage, uint256 frequency, uint256 tenor)
        TimelockIERC1155(initialOwner, tenor)
        SimpleInterestVault(asset, interestRatePercentage, frequency, tenor)
    { }

    // we want the supply of the ERC20 token - not the locks
    function totalSupply() public view virtual override(ERC1155Supply, IERC20, ERC20) returns (uint256) {
        return ERC20.totalSupply();
    }
}
