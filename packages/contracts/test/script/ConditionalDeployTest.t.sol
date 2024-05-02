//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { ConditionalDeploy } from "../../script/ConditionalDeploy.s.sol";

contract ConditionalDeployTest is Test {
    function test__ConditionalDeploy() public {
        ConditionalDeployMock conditionalDeploy = new ConditionalDeployMock(false);

        assertEq(address(0), conditionalDeploy.deployIfNeeded());
        assertTrue(conditionalDeploy.parentShouldDeploy());

        conditionalDeploy.setShouldDeployFlag(true);
        assertEq(conditionalDeploy.newAddress(), conditionalDeploy.deployIfNeeded());
    }
}

contract ConditionalDeployMock is ConditionalDeploy {
    string public constant NAME = "ConditionalDeployImpl";
    address public newAddress = makeAddr("newAddress");

    bool public shouldDeployFlag;

    constructor(bool _shouldDeployFlag) ConditionalDeploy(NAME) {
        shouldDeployFlag = _shouldDeployFlag;
    }

    function newInstance() public view override returns (address) {
        return newAddress;
    }

    function parentShouldDeploy() public returns (bool) {
        return super.shouldDeploy();
    }

    function shouldDeploy() public view override returns (bool) {
        return shouldDeployFlag;
    }

    function setShouldDeployFlag(bool _shouldDeployFlag) public {
        shouldDeployFlag = _shouldDeployFlag;
    }
}
