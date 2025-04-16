//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { WrappedERC20 } from "@credbull/token/ERC20/WrappedERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

contract DeployWrappedERC20 is Script {
    uint256 private constant PRECISION = 1e18;
    IERC20 private _underlyingToken;

    constructor(IERC20 underlyingToken) {
        _underlyingToken = underlyingToken;
    }

    function run(WrappedERC20.Params memory params) public returns (WrappedERC20 wrappedToken) {
        vm.startBroadcast();

        wrappedToken = new WrappedERC20(params);
        console2.log(string.concat("!!!!! Deploying WrappedERC20 [", vm.toString(address(wrappedToken)), "] !!!!!"));
        vm.stopBroadcast();

        return wrappedToken;
    }
}
