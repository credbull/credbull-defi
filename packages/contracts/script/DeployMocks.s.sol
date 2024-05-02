//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { MockStablecoin } from "../test/mocks/MockStablecoin.sol";
import { MockToken } from "../test/mocks/MockToken.sol";
import { console2 } from "forge-std/console2.sol";
import { ConditionalDeploy } from "./ConditionalDeploy.s.sol";

/// @title Deploy the MockToken contract
contract DeployMockToken is ConditionalDeploy {
    constructor() ConditionalDeploy("MockToken") { }

    function newInstance() public override returns (address) {
        MockToken token = new MockToken(type(uint128).max);
        return address(token);
    }
}

/// @title Deploy the MockStablecoin contract.
contract DeployMockStablecoin is ConditionalDeploy {
    constructor() ConditionalDeploy("MockStablecoin") { }

    function newInstance() public override returns (address) {
        MockStablecoin mockStablecoin = new MockStablecoin(type(uint128).max);
        return address(mockStablecoin);
    }
}
