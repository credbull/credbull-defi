//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { HelperConfig } from "@script/HelperConfig.s.sol";

import { VaultUpgradeable } from "@credbull/vault/upgradeable/VaultUpgradeable.sol";
import { Vault } from "@credbull/vault/Vault.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { ParamsFactory } from "@test/test/vault/utils/ParamsFactory.t.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { console2 } from "forge-std/console2.sol";
import { SimpleUSDC } from "@test/test/token/SimpleUSDC.t.sol";

contract SimpleVaultUpgradeable is VaultUpgradeable {
    uint256 public stateVariable;

    function withdrawERC20(address[] calldata _tokens, address _to) external {
        _withdrawERC20(_tokens, _to);
    }

    function setVariable() public {
        stateVariable = 1;
    }
}

contract SimpleVaultUpgradeableV2 is SimpleVaultUpgradeable {
    uint256 public newStateVariable;

    function newVersionMethod() external pure returns (string memory) {
        return "v2";
    }

    function setVariableNew() public {
        newStateVariable = 2;
    }
}

contract VaultUpgradeableTest is Test {
    SimpleVaultUpgradeable private vault;
    ERC1967Proxy private vaultProxy;

    using Math for uint256;

    HelperConfig private helperConfig;

    Vault.VaultParams private vaultParams;

    address private alice = makeAddr("alice");
    address private bob = makeAddr("bob");

    uint256 private precision;

    uint256 private constant INITIAL_BALANCE = 1e6;
    uint256 private constant MAX_PERCENTAGE = 100_00;

    function setUp() public {
        vault = new SimpleVaultUpgradeable();
        helperConfig = new HelperConfig(true);
        vaultParams = new ParamsFactory(helperConfig.getNetworkConfig()).createVaultParams();
        VaultUpgradeable.VaultParams memory vaultUpgradeableParams = VaultUpgradeable.VaultParams({
            asset: vaultParams.asset,
            shareName: vaultParams.shareName,
            shareSymbol: vaultParams.shareSymbol,
            custodian: vaultParams.custodian
        });

        precision = 10 ** SimpleUSDC(address(vaultParams.asset)).decimals();

        SimpleUSDC(address(vaultParams.asset)).mint(alice, INITIAL_BALANCE * precision);
        SimpleUSDC(address(vaultParams.asset)).mint(bob, INITIAL_BALANCE * precision);

        console2.log("Implementation address: ", address(vault));

        vaultProxy =
            new ERC1967Proxy(address(vault), abi.encodeCall(VaultUpgradeable.initialize, vaultUpgradeableParams));

        console2.log("Proxy address: ", address(vaultProxy));

        vault = SimpleVaultUpgradeable(address(vaultProxy));
        vault.setVariable();
    }

    function test__VaultUpgradeable__initialize() public {
        assertEq(vault.CUSTODIAN(), vaultParams.custodian);
        assertEq(vault.VAULT_DECIMALS(), ERC20(address(vaultParams.asset)).decimals());
    }

    function test__VaultUpgradeable__ShouldUpgradeToV2() public {
        SimpleVaultUpgradeableV2 newVault = new SimpleVaultUpgradeableV2();
        vault.upgradeToAndCall(address(newVault), "");
        SimpleVaultUpgradeableV2 vaultV2 = SimpleVaultUpgradeableV2(address(vaultProxy));
        assertEq(vaultV2.newVersionMethod(), "v2");
    }

    function test__VaultUpgradeable__ShouldRetainStates() public {
        uint256 amount = 1000e6;

        // 1. Deposit
        vm.startPrank(alice);
        vaultParams.asset.approve(address(vault), amount);

        vault.deposit(amount, alice);
        vm.stopPrank();

        assertEq(vault.totalAssetDeposited(), amount);

        // 2. Upgrade contract
        SimpleVaultUpgradeableV2 newVault = new SimpleVaultUpgradeableV2();
        vault.upgradeToAndCall(address(newVault), "");
        SimpleVaultUpgradeableV2 vaultV2 = SimpleVaultUpgradeableV2(address(vaultProxy));
        assertEq(vaultV2.newVersionMethod(), "v2");

        // 3. Deposit again and assert the totalAssetDeposited
        vm.startPrank(alice);
        vaultParams.asset.approve(address(vaultV2), amount);

        vaultV2.deposit(amount, alice);
        vm.stopPrank();

        assertEq(vaultV2.totalAssetDeposited(), amount * 2);
    }

    function test__VaultUpgradeable__StorageVariable() public {
        uint256 valueBeforeUpgrade = vault.stateVariable();
        console2.log("value before upgrade", valueBeforeUpgrade);

        SimpleVaultUpgradeableV2 newVault = new SimpleVaultUpgradeableV2();
        vault.upgradeToAndCall(address(newVault), "");
        SimpleVaultUpgradeableV2 vaultv2 = SimpleVaultUpgradeableV2(address(vault));
        vaultv2.setVariableNew();

        uint256 valueAfterUpgrade = vaultv2.newStateVariable();
        console2.log("value after upgrade", valueAfterUpgrade);
    }
}
