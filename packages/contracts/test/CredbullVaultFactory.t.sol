//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { CredbullVaultFactory } from "../src/CredbullVaultFactory.sol";
import { DeployVaultFactory } from "../script/DeployVaultFactory.s.sol";
import { HelperConfig, NetworkConfig } from "../script/HelperConfig.s.sol";
import { ICredbull } from "../src/interface/ICredbull.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { CredbullVault } from "../src/CredbullVault.sol";

contract CredbullVaultFactoryTest is Test {
    CredbullVaultFactory factory;
    DeployVaultFactory private deployer;
    HelperConfig private helperConfig;

    function setUp() public {
        deployer = new DeployVaultFactory();
        (factory, helperConfig) = deployer.runTest();
    }

    function test__CreateVaultFromFactory() public {
        NetworkConfig memory config = helperConfig.getNetworkConfig();
        ICredbull.VaultParams memory params = config.vaultParams;

        vm.prank(params.owner);
        CredbullVault vault = factory.createVault(params);

        assertEq(vault.owner(), params.owner);
        assertEq(vault.asset(), address(params.asset));
        assertEq(vault.name(), params.shareName);
        assertEq(vault.symbol(), params.shareSymbol);
        assertEq(address(vault.kycProvider()), params.kycProvider);
        assertEq(vault.custodian(), params.custodian);
    }

    function test__VaultCountShouldReturnCorrectVault() public {
        createVault();
        assertEq(factory.getTotalVaultCount(), 1);
    }

    function test__ShouldReturnVaultAtIndex() public {
        CredbullVault vault = createVault();
        assertEq(factory.getVaultAtIndex(0), address(vault));
    }

    function test__ShouldReturnVaultExistStatus() public {
        CredbullVault vault = createVault();
        assertEq(factory.isVaultExist(address(vault)), true);
    }

    function test__ShouldUpdateEntitesData() public {
        CredbullVault vault = createVault();

        ICredbull.EntitiesData memory _entities = getEntitiesData();

        vm.prank(factory.owner());
        factory.updateEntitesData(address(vault), _entities);

        ICredbull.EntitiesData memory addedEntityData = factory.getEntitiesData(address(vault));
        assertEq(addedEntityData.entities, _entities.entities);
        assertEq(addedEntityData.percentage, _entities.percentage);
    }

    function test__ShouldRevertEntityUpdateOnInvalidData() public {
        CredbullVault vault = createVault();

        address[] memory entities = new address[](2);
        entities[0] = makeAddr("entity1");
        entities[1] = makeAddr("entity2");

        uint256[] memory percentage = new uint256[](1);
        percentage[0] = 8_00;

        ICredbull.EntitiesData memory _entites = ICredbull.EntitiesData({ entities: entities, percentage: percentage });

        vm.prank(factory.owner());
        vm.expectRevert(CredbullVaultFactory.CredbullVaultFactory__InvalidEntitiesData.selector);
        factory.updateEntitesData(address(vault), _entites);
    }

    function test__ShouldRevertIfVaultDoesntExist() public {
        ICredbull.EntitiesData memory _entities = getEntitiesData();

        address vault = makeAddr("dummy_vault");
        vm.prank(factory.owner());
        vm.expectRevert(
            abi.encodeWithSelector(CredbullVaultFactory.CredbullVaultFactory__VaultDoestExist.selector, vault)
        );
        factory.updateEntitesData(vault, _entities);
    }

    function test__ShouldCreateAndUpdateEntitiesData() public {
        NetworkConfig memory config = helperConfig.getNetworkConfig();
        ICredbull.VaultParams memory params = config.vaultParams;

        ICredbull.EntitiesData memory _entities = getEntitiesData();

        vm.prank(factory.owner());
        factory.createVaultAndUpdateEntities(params, _entities);

        address vault = factory.getVaultAtIndex(0);

        ICredbull.EntitiesData memory addedEntityData = factory.getEntitiesData(vault);
        assertEq(addedEntityData.entities, _entities.entities);
        assertEq(addedEntityData.percentage, _entities.percentage);
    }

    function getEntitiesData() internal returns (ICredbull.EntitiesData memory _entitiesData) {
        address[] memory entities = new address[](2);
        entities[0] = makeAddr("entity1");
        entities[1] = makeAddr("entity2");

        uint256[] memory percentage = new uint256[](2);
        percentage[0] = 8_00;
        percentage[1] = 10_00;

        _entitiesData = ICredbull.EntitiesData({ entities: entities, percentage: percentage });
    }

    function createVault() internal returns (CredbullVault vault) {
        NetworkConfig memory config = helperConfig.getNetworkConfig();
        ICredbull.VaultParams memory params = config.vaultParams;

        vm.prank(params.owner);
        vault = factory.createVault(params);
    }
}
