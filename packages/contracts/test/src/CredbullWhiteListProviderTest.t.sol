//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { CredbullWhiteListProvider } from "@credbull/CredbullWhiteListProvider.sol";
import { WhiteListProvider } from "@credbull/provider/whiteList/WhiteListProvider.sol";

contract CredbullWhiteListProviderTest is Test {
    CredbullWhiteListProvider private whiteListProvider;
    address private owner = makeAddr("owner");
    address private alice = makeAddr("alice");

    function setUp() public {
        whiteListProvider = new CredbullWhiteListProvider(owner);
    }

    function test__WhiteListProvider__SuccessfullyDeployWhiteListProvider() public {
        whiteListProvider = new CredbullWhiteListProvider(owner);
        assertEq(whiteListProvider.owner(), owner);
    }

    function test__WhiteListProvider__RevertWhiteListProviderUpdateStatusIfLengthMismatch() public {
        address[] memory whitelistAddresses = new address[](1);
        whitelistAddresses[0] = alice;

        bool[] memory statuses = new bool[](2);
        statuses[0] = true;
        statuses[1] = true;

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(WhiteListProvider.LengthMismatch.selector));
        whiteListProvider.updateStatus(whitelistAddresses, statuses);
    }
}
