//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { ICredbull } from "../../src/interface/ICredbull.sol";
import { NetworkConfig, HelperConfig } from "../../script/HelperConfig.s.sol";
import { MockStablecoin } from "../mocks/MockStablecoin.sol";
import { CredbullFixedYieldVault } from "../../src/CredbullFixedYieldVault.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

contract CredbullFixedYieldVaultTest is Test {
    CredbullFixedYieldVault private vault;
    HelperConfig private helperConfig;

    ICredbull.VaultParams private vaultParams;

    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");

    uint256 decimals;
    uint256 private constant INITIAL_BALANCE = 1000;

    function setUp() public {
        helperConfig = new HelperConfig();
        NetworkConfig memory config = helperConfig.getNetworkConfig();
        vaultParams = config.vaultParams;
        vault = new CredbullFixedYieldVault(vaultParams);

        address[] memory whitelistAddresses = new address[](2);
        whitelistAddresses[0] = alice;
        whitelistAddresses[1] = bob;

        bool[] memory statuses = new bool[](2);
        statuses[0] = true;
        statuses[1] = true;

        vm.startPrank(vaultParams.owner);
        vault.kycProvider().updateStatus(whitelistAddresses, statuses);
        vm.stopPrank();

        decimals = MockStablecoin(address(vaultParams.asset)).decimals();

        MockStablecoin(address(vaultParams.asset)).mint(alice, INITIAL_BALANCE * decimals);
        MockStablecoin(address(vaultParams.asset)).mint(bob, INITIAL_BALANCE * decimals);
    }

    function test__FixedYieldVault__ShouldAllowOwnerToChangeOperator() public {
        address newOperator = makeAddr("new_operator");

        vm.startPrank(vaultParams.owner);
        vault.revokeRole(vault.OPERATOR_ROLE(), vaultParams.operator);
        vault.grantRole(vault.OPERATOR_ROLE(), newOperator);
        vm.stopPrank();

        vm.startPrank(vaultParams.operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, vaultParams.operator, vault.OPERATOR_ROLE()
            )
        );
        vault.mature();
        vm.stopPrank();

        vm.startPrank(newOperator);
        vault.mature();
        vm.stopPrank();
    }

    function test__FixedYieldVault__ShouldAllowOnlyOperatorToMatureVault() public {
        vm.startPrank(vaultParams.owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, vaultParams.owner, vault.OPERATOR_ROLE()
            )
        );
        vault.mature();
        vm.stopPrank();
    }

    function test__FixedYieldVault__RevertMatureIfNotOperator() public {
        vm.startPrank(vaultParams.owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, vaultParams.owner, vault.OPERATOR_ROLE()
            )
        );
        vault.mature();
        vm.stopPrank();
    }

    function test__FixedYieldVault__RevertMaturityToggleIfNotOperator() public {
        vm.startPrank(vaultParams.operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                vaultParams.operator,
                vault.DEFAULT_ADMIN_ROLE()
            )
        );
        vault.toggleMaturityCheck(false);
        vm.stopPrank();
    }

    function test__FixedYieldVault__RevertWhitelistToggleIfNotOperator() public {
        vm.startPrank(vaultParams.operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                vaultParams.operator,
                vault.DEFAULT_ADMIN_ROLE()
            )
        );
        vault.toggleWhitelistCheck(false);
        vm.stopPrank();
    }

    function test__FixedYieldVault__RevertWindowToggleIfNotOperator() public {
        vm.startPrank(vaultParams.operator);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                vaultParams.operator,
                vault.DEFAULT_ADMIN_ROLE()
            )
        );
        vault.toggleWhitelistCheck(false);
        vm.stopPrank();
    }
}
