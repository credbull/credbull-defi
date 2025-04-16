//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { CredbullERC20Wrapper } from "@test/test/token/CredbullERC20Wrapper.t.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

contract DeployCredbullERC20Wrapper is Script {
    uint256 private constant PRECISION = 1e18;
    IERC20 private _underlyingToken;

    constructor(IERC20 underlyingToken) {
        _underlyingToken = underlyingToken;
    }

    function run(CredbullERC20Wrapper.Params memory params) public returns (CredbullERC20Wrapper erc20Wrapper) {
        vm.startBroadcast();

        erc20Wrapper = new CredbullERC20Wrapper(params);
        console2.log(
            string.concat("!!!!! Deploying CredbullERC20Wrapper [", vm.toString(address(erc20Wrapper)), "] !!!!!")
        );
        vm.stopBroadcast();

        return erc20Wrapper;
    }
}
