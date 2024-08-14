// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test } from "forge-std/Test.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { SimpleToken } from "@test/test/token/SimpleToken.t.sol";

import { HelperConfig } from "@script/HelperConfig.s.sol";
import { Vault } from "@credbull/vault/Vault.sol";
import { SimpleVault } from "@test/test/vault/SimpleVault.t.sol";
import { ParamsFactory } from "@test/test/vault/utils/ParamsFactory.t.sol";

contract BatchManager {
    struct BatchInfo {
        address vaultAddress;
        uint256 fromTimestamp;
        uint256 toTimestamp;
    }

    BatchInfo[] public batches;

    error BatchManager__VaultNotFoundForTimestamp(uint256);

    event NewBatchCreated(address indexed vaultAddress, uint256 fromTimestamp, uint256 toTimestamp);

    function createNewBatch(address vaultAddress, uint256 duration) public {
        uint256 fromTimestamp = block.timestamp;
        uint256 toTimestamp = block.timestamp + duration;

        BatchInfo memory newBatch = BatchInfo(vaultAddress, fromTimestamp, toTimestamp);
        batches.push(newBatch);

        emit NewBatchCreated(vaultAddress, fromTimestamp, toTimestamp);
    }

    function getVaultForTimestamp(uint256 timestamp) public view returns (address) {
        for (uint256 i = 0; i < batches.length; i++) {
            if (timestamp >= batches[i].fromTimestamp && timestamp <= batches[i].toTimestamp) {
                return batches[i].vaultAddress;
            }
        }

        revert BatchManager__VaultNotFoundForTimestamp(timestamp);
    }
}

contract BatchManagerTest is Test {
    BatchManager private batchManager;
    IERC20 private token;

    SimpleVault private vault;
    HelperConfig private helperConfig;

    Vault.VaultParams private vaultParams;

    function setUp() public {
        token = new SimpleToken(10000);
        batchManager = new BatchManager();

        helperConfig = new HelperConfig(true);
        vaultParams = new ParamsFactory(helperConfig.getNetworkConfig()).createVaultParams();

        vault = new SimpleVault(vaultParams);
    }

    function test__BatchManagerTest__CreateNewBatch() public {
        uint256 duration = 1 weeks;

        batchManager.createNewBatch(address(vault), duration);

        // Verify that the new batch has been created
        (address vaultAddress, uint256 fromTimestamp, uint256 toTimestamp) = batchManager.batches(0);
        assertEq(vaultAddress, address(vault));
        assertEq(fromTimestamp, block.timestamp);
        assertEq(toTimestamp, block.timestamp + duration);
    }

    function test__BatchManagerTest__GetVaultForTimestamp() public {
        uint256 duration = 1 weeks;
        batchManager.createNewBatch(address(vault), duration);

        // Advance the block timestamp
        vm.warp(block.timestamp + 3 days);

        // Verify that the correct vault is retrieved
        address retrievedVault = batchManager.getVaultForTimestamp(block.timestamp);
        assertEq(retrievedVault, address(vault));
    }

    function test__BatchManagerTest__GetVaultForInvalidTimestamp() public {
        uint256 duration = 1 weeks;
        batchManager.createNewBatch(address(vault), duration);

        // Advance the block timestamp past the duration
        vm.warp(block.timestamp + duration + 1 days);

        // Expect revert when trying to retrieve a vault for an invalid timestamp
        vm.expectRevert();
        batchManager.getVaultForTimestamp(block.timestamp);
    }
}
