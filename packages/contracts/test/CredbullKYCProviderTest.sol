//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { CredbullKYCProvider } from "../src/CredbullKYCProvider.sol";

contract CredbullKYCProviderTest is Test {
    CredbullKYCProvider private kycProvider;
    address private owner = makeAddr("owner");
    address private alice = makeAddr("alice");

    function setUp() public {
        kycProvider = new CredbullKYCProvider(owner);
    }

    function test__SuccessfullyDeployKYCProvider() public {
        kycProvider = new CredbullKYCProvider(owner);
        assertEq(kycProvider.owner(), owner);
    }

    function test__UpsideVault__RevertKYCProviderUpdateStatusIfLengthMismatch() public {
        address[] memory whitelistAddresses = new address[](1);
        whitelistAddresses[0] = alice;

        bool[] memory statuses = new bool[](2);
        statuses[0] = true;
        statuses[1] = true;

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(CredbullKYCProvider.LengthMismatch.selector));
        kycProvider.updateStatus(whitelistAddresses, statuses);
    }
}
