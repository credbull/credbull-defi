//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title Credbull Short Term Fixed Yield Vault
 * @notice The family defining contract, based upon Open Zeppelin's ERC4626 implementation.
 * @dev Uses a Custodian Account to accummulate the deposited Asset.
 */
abstract contract ShortTermFixedYieldVault is ERC4626, Pausable {
  using Math for uint256;
}
