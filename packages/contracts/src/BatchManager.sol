// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
// import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

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
