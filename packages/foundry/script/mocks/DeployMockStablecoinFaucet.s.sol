// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { MockStablecoin } from "../../test/mocks/MockStablecoin.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { console } from "forge-std/console.sol";

import { ScaffoldETHDeploy } from "../DeployHelpers.s.sol";
import "../../test/mocks/MockStablecoinFaucet.sol";


contract DeployMockStablecoinFaucet is ScaffoldETHDeploy {

    function run(address contractOwnerAddress, MockStablecoin mockStablecoin) public returns (MockStablecoinFaucet) {
        vm.startBroadcast(contractOwnerAddress);

        MockStablecoinFaucet faucet = new MockStablecoinFaucet(mockStablecoin);
        mockStablecoin.mint(address(faucet), 1000);

        vm.stopBroadcast();

        exportDeployments(); // generates file with Abi's.  call this last.

        return faucet;
    }
}
