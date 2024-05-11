//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";

import { DeployMocks } from "../../script/DeployMocks.s.sol";
import { MockStablecoin } from "../mocks/MockStablecoin.sol";
import { MockToken } from "../mocks/MockToken.sol";

contract DeployMocksTest is Test, DeployMocks {
    constructor() DeployMocks(true, makeAddr("custodian")) { }

    function test__DeployMocksTest__DeployMocks() public {
        (MockToken mockToken, MockStablecoin mockStablecoin) = run();

        assertNotEq(address(0), address(mockToken));
        assertNotEq(address(0), address(mockStablecoin));
        assertNotEq(address(0), address(credbullBaseVaultMock));

        assertEq(totalSupply, mockToken.totalSupply());
        assertEq(totalSupply, mockStablecoin.totalSupply());
    }
}
