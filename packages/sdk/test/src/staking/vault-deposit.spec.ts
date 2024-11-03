import { expect, test } from '@playwright/test';
import { BigNumber } from 'ethers';
import * as path from 'path';

import { createProcessedLogger, initProcessedLogCache, processedLogCache } from '../utils/logger';

import { VaultDeposit } from './vault-deposit';
import { VaultDepositApp } from './vault-deposit-app';

test.beforeAll(async () => {});

test.describe('Test Vault Deposit for all', () => {
  test('Test Deposit all', async () => {
    const vaultDepositApp = new VaultDepositApp();

    await vaultDepositApp.loadDeposits('TEST-staking-data.json');
  });
});

test.describe('Test VaultDeposit Utility functions', () => {
  const vaultDeposit = new VaultDeposit(
    -1,
    '0x14dC79964da2C08b23698B3D3cc7Ca32193d9955',
    BigNumber.from('7000000000000000000'),
  );

  test('should set all fields on json', async () => {
    // Act: Call the toJson method
    const jsonResult = vaultDeposit.toJson();

    // Assert: Check that jsonResult matches the expected JSON structure and values
    expect(jsonResult).toEqual({
      VaultDeposit: {
        id: vaultDeposit._id,
        receiver: vaultDeposit._receiver,
        depositAmount: vaultDeposit._depositAmount.toString(),
      },
    });
  });

  test('should log as json and determine if processed', async () => {
    const chainId = 31137;

    const testLogFilePath = path.join(__dirname, '../../../logs/test-staking-processed.json');

    // Clear log cache and initialize it for the test log file
    processedLogCache.length = 0;
    initProcessedLogCache(testLogFilePath);

    // Create a test-specific logger pointing to test-staking-processed.json
    const testProcessedLogger = createProcessedLogger(testLogFilePath);

    expect(await vaultDeposit.isProcessed(chainId, processedLogCache)).toBe(false); // Should not be processed initially

    // Act: Call logResult using the test-specific logger
    const txnHash = '0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef';
    await vaultDeposit.logResult(chainId, txnHash, testProcessedLogger);

    // Check if the log entry is correctly stored in logMessages
    expect(processedLogCache[0]).toEqual({
      level: 'info',
      message: {
        chainId: chainId,
        txnHash: txnHash,
        ...vaultDeposit.toJson(),
      },
      timestamp: expect.any(String), // Include timestamp since it's auto-generated
    });

    console.log(`%% Test isProcessed LogMessage: ${JSON.stringify(processedLogCache[0], null, 2)}`);

    expect(await vaultDeposit.isProcessed(chainId, processedLogCache)).toBe(true); // Now processed
  });
});
