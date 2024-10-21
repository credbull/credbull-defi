import { expect, test } from '@playwright/test';
import { ethers } from 'ethers';

let provider: ethers.providers.JsonRpcProvider;

test.beforeAll(async () => {
  provider = new ethers.providers.JsonRpcProvider(); // no url, defaults to 'http://localhost:8545'
});

// See: https://github.com/safe-global/safe-core-sdk/tree/main/packages/protocol-kit
test.describe.skip('Warp ahead in time on Anvil', () => {
  test('Warp time forward by 1 day and check new block timestamp', async () => {
    // Fetch the current block number and timestamp
    const blockNumber = await provider.getBlockNumber();
    const block = await provider.getBlock(blockNumber);
    const currentBlockTime = block.timestamp;

    console.log('Current Block Time:', new Date(currentBlockTime * 1000).toLocaleString());

    const oneDayInSeconds = 24 * 60 * 60; // 1 day (86400 seconds)

    await provider.send('evm_increaseTime', [oneDayInSeconds]);
    await provider.send('evm_mine', []); // Mine a new block to apply the time change

    // Fetch the new block timestamp
    const newBlockNumber = await provider.getBlockNumber();
    const newBlock = await provider.getBlock(newBlockNumber);
    const newBlockTime = newBlock.timestamp;

    console.log('New Block Time:', new Date(newBlockTime * 1000).toLocaleString());

    // Assert the new block time is within a reasonable range of the expected time
    const toleranceInSeconds = 100; // Allow for a 100-second tolerance
    const expectedBlockTime = currentBlockTime + oneDayInSeconds;

    expect(newBlockTime).toBeGreaterThanOrEqual(expectedBlockTime - toleranceInSeconds);
    expect(newBlockTime).toBeLessThanOrEqual(expectedBlockTime + toleranceInSeconds);
  });
});
