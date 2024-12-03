import { expect, test } from '@playwright/test';
import { BigNumber } from 'ethers';
import * as path from 'path';

import { createProcessedLogger, initProcessedLogCache, processedLogCache } from '../utils/logger';

import { VaultDeposit } from './vault-deposit';
import { LoadDepositResult, VaultDepositApp } from './vault-deposit-app';

test.beforeAll(async () => {});

export const TEST_VAULT_DEPOSIT_0_FILENAME = 'TEST-vault-deposit-0.json';
export const TEST_VAULT_DEPOSIT_3_FILENAME = 'TEST-vault-deposit-3.json';
export const TEST_VAULT_DEPOSIT_50_FILENAME = 'TEST-vault-deposit-50.json';
export const TEST_VAULT_DEPOSIT_1000_FILENAME = 'TEST-vault-deposit-1000.json';

test.describe('Test Vault Deposit for all', () => {
  test.skip('Load Test Deposit 1000', async () => {
    test.setTimeout(3600000); // Set timeout to 1 hour (3,600,000 ms) - 1000 would take an hour on Arb!
    const vaultDepositApp = new VaultDepositApp();

    const result: LoadDepositResult = await vaultDepositApp.loadDeposits(TEST_VAULT_DEPOSIT_1000_FILENAME);
    expect(result.successes.length).toBe(997); // IDs 7,8,9 will be skipped from Test Deposit 3
    expect(result.fails.length).toBe(0);
    expect(result.skipped.length).toBe(3); // IDs 7,8,9 will be skipped from Test Deposit 3
  });

  test('Test Deposit empty json should process nothing', async () => {
    const vaultDepositApp = new VaultDepositApp();

    const resultEmpty: LoadDepositResult = await vaultDepositApp.loadDeposits(TEST_VAULT_DEPOSIT_0_FILENAME);
    expect(resultEmpty.successes.length).toBe(0);
    expect(resultEmpty.fails.length).toBe(0);
    expect(resultEmpty.skipped.length).toBe(0);
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
