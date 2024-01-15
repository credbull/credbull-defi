// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import { console2 } from "forge-std/console2.sol";

contract CredbullEntities {
    address public custodian;
    address public treasury;
    address public activityReward;

    constructor(address _custodian, address _treasury, address _activityReward) {
        custodian = _custodian;
        treasury = _treasury;
        activityReward = _activityReward;
    }
}
