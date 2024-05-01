//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { MockStablecoin } from "../test/mocks/MockStablecoin.sol";
import { MockToken } from "../test/mocks/MockToken.sol";
import { ICredbull } from "../src/interface/ICredbull.sol";
import { stdJson } from "forge-std/StdJson.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { console2 } from "forge-std/console2.sol";

contract DeployMocks is Script {
    bool private test = true;

    using stdJson for string;

    function deployMockToken() public returns (MockToken) {
        vm.startBroadcast();
        MockToken token = new MockToken(type(uint128).max);
        console2.log("!!!!! Deploying MockToken !!!!!");
        vm.stopBroadcast();

        return token;
    }

    function deployMockStablecoin() public returns (MockStablecoin) {
        vm.startBroadcast();
        MockStablecoin usdc = new MockStablecoin(type(uint128).max);
        console2.log("!!!!! Deploying MockStablecoin !!!!!");
        vm.stopBroadcast();

        return usdc;
    }

    // TODO: change this to return the previously deployed contract
    function isPreviouslyDeployed(string memory contractName) public returns (bool) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/script/output/dbdata.json");

        if (vm.exists(path)) {
            string memory json = vm.readFile(path);

            bytes memory jsonContract = json.parseRaw(string.concat(".", contractName));

            return jsonContract.length > 0;
        }

        return false;
    }

    function deployMocksOrSkipIfPreviouslyDeployed() public returns (address, address) {
        MockToken token;
        MockStablecoin usdc;

        if (isPreviouslyDeployed("MockToken")) {
            console2.log("!!!!! Deployment skipped for MockToken !!!!!");
        } else {
            token = deployMockToken();
        }

        if (isPreviouslyDeployed("MockStablecoin")) {
            console2.log("!!!!! Deployment skipped for MockStablecoin !!!!!");
        } else {
            usdc = deployMockStablecoin();
        }

        return (address(token), address(usdc));
    }
}
