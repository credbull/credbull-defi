//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { TomlConfig } from "@script/TomlConfig.s.sol";

import { AggregateToken } from "@plume/contracts/nest/AggregateToken.sol";
import { AggregateTokenProxy } from "@plume/contracts/nest/proxy/AggregateTokenProxy.sol";
import { IComponentToken } from "@plume/contracts/nest/interfaces/IComponentToken.sol";

import { stdToml } from "forge-std/StdToml.sol";
import { console2 } from "forge-std/console2.sol";

contract DeployAggregateToken is TomlConfig {
    using stdToml for string;

    string private _tomlConfig;

    constructor() {
        _tomlConfig = loadTomlConfiguration();
    }

    function run() public returns (AggregateToken aggregateToken_) {
        address contractOwner = _tomlConfig.readAddress(".evm.address.owner");
        address usdcAddress = _tomlConfig.readAddress(".evm.address.usdc_token");

        return run(contractOwner, usdcAddress);
    }

    function run(address contractOwner, address assetAddress) public virtual returns (AggregateToken aggregateToken_) {
        vm.startBroadcast();

        // Deploy AggregateToken with both component tokens
        AggregateToken aggregateToken = new AggregateToken();
        console2.log("AggregateTokenImpl deployed to:", address(aggregateToken));

        AggregateTokenProxy aggregateTokenProxy = new AggregateTokenProxy(
            address(aggregateToken),
            abi.encodeCall(
                AggregateToken.initialize,
                (
                    contractOwner,
                    "Cranberry (Credbull Test Aggregate Token)",
                    "CRAN",
                    IComponentToken(assetAddress),
                    1e17, // ask price
                    1e17 // bid price
                )
            )
        );
        console2.log("AggregateTokenProxy deployed to:", address(aggregateTokenProxy));

        vm.stopBroadcast();

        return AggregateToken(address(aggregateTokenProxy));
    }
}
