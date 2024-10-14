//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";

import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { SimpleTimelockAsyncUnlock } from "@test/test/timelock/SimpleTimelockAsyncUnlock.t.sol";
import { ERC1155MintableBurnable } from "@test/test/token/ERC1155/ERC1155MintableBurnable.t.sol";
import { IERC5679Ext1155 } from "@credbull/token/ERC1155/IERC5679Ext1155.sol";

import { console2 } from "forge-std/console2.sol";

contract DeployTimelockAsyncUnlock is Script {
    function run() public {
        vm.startBroadcast();

        IERC5679Ext1155 deposits = new ERC1155MintableBurnable();
        uint256 notice_period = 1;

        SimpleTimelockAsyncUnlock asyncUnlockImpl = new SimpleTimelockAsyncUnlock();

        ERC1967Proxy asyncUnlockProxy = new ERC1967Proxy(
            address(asyncUnlockImpl),
            abi.encodeWithSelector(asyncUnlockImpl.initialize.selector, notice_period, deposits)
        );

        console2.log(
            string.concat(
                "!!!!! Deploying SimpleTimelockAsyncUnlock Proxy [", vm.toString(address(asyncUnlockProxy)), "] !!!!!"
            )
        );

        vm.stopBroadcast();
    }
}
