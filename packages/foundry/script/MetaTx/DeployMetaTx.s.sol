//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {MetaVault} from "../../contracts/MetaTx/MetaVault.sol";
import {MockERC20Permit} from "../../test/mocks/MockERC20Permit.sol";
import { ERC2771Forwarder } from "@openzeppelin/contracts/metatx/ERC2771Forwarder.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract DeployMetaTx is Script {
    MetaVault vault;
    MockERC20Permit usdc;
    ERC2771Forwarder forwarder;

    function run() external returns(MetaVault) {
        uint256 deployerPrivateKey = vm.envUint("ANVIL_PRIVATE_KEY");
        address user = 0x06457f819Bf569DD00DF321740cd4BBDc367872c;
        vm.startBroadcast(deployerPrivateKey);
        usdc = new MockERC20Permit();
        usdc.mint(user, 1000 ether);

        forwarder = new ERC2771Forwarder("Cred");

        vault = new MetaVault("Test", "t", IERC20(usdc), forwarder);
        vm.stopBroadcast();
        return vault;
    }
}