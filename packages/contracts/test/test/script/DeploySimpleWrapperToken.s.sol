//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { DeployCBLToken, CBLTokenParams } from "@script/DeployCBLToken.s.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Script } from "forge-std/Script.sol";
import { SimpleWrapperToken } from "@test/test/token/SimpleWrapperToken.t.sol";
import { console2 } from "forge-std/console2.sol";

contract DeploySimpleWrapperToken is Script {
    uint256 private constant PRECISION = 1e18;
    IERC20 private _underlyingToken;

    constructor(IERC20 underlyingToken) {
        _underlyingToken = underlyingToken;
    }

    function run(SimpleWrapperToken.SimpleWrapperTokenParams memory params)
        public
        returns (SimpleWrapperToken simpleWrapperToken)
    {
        vm.startBroadcast();

        simpleWrapperToken = new SimpleWrapperToken(params);
        console2.log(
            string.concat("!!!!! Deploying SimpleWrapperToken [", vm.toString(address(simpleWrapperToken)), "] !!!!!")
        );
        vm.stopBroadcast();

        return simpleWrapperToken;
    }
}
