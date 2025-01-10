import { expect, test } from '@playwright/test';

import { LoadDepositResult, VaultDepositApp } from './vault-deposit-app';

test.beforeAll(async () => {});

export const TEST_DEPOSIT_0_FILENAME = 'TEST-deposit-0.json';
export const TEST_DEPOSIT_3_FILENAME = 'TEST-deposit-3.json';
export const TEST_DEPOSIT_1000_FILENAME = 'TEST-deposit-1000.json';

test.describe('Test Vault Deposit for all', () => {
  test('Test Deposit 3', async () => {
    const vaultDepositApp = new VaultDepositApp();

    const result: LoadDepositResult = await vaultDepositApp.loadDeposits(TEST_DEPOSIT_3_FILENAME);
    expect(result.successes.length).toBe(3);
    expect(result.fails.length).toBe(0);
    expect(result.skipped.length).toBe(0);

    // call it again - now should skip them all
    const resultSkipped: LoadDepositResult = await vaultDepositApp.loadDeposits(TEST_DEPOSIT_3_FILENAME);
    expect(resultSkipped.successes.length).toBe(0);
    expect(resultSkipped.fails.length).toBe(0);
    expect(resultSkipped.skipped.length).toBe(3);
  });

  test.skip('Load Test Deposit 1000', async () => {
    test.setTimeout(3600000); // Set timeout to 1 hour (3,600,000 ms) - 1000 would take an hour on Arb!
    const vaultDepositApp = new VaultDepositApp();

    const result: LoadDepositResult = await vaultDepositApp.loadDeposits(TEST_DEPOSIT_1000_FILENAME);
    expect(result.successes.length).toBe(997); // IDs 7,8,9 will be skipped from Test Deposit 3
    expect(result.fails.length).toBe(0);
    expect(result.skipped.length).toBe(3); // IDs 7,8,9 will be skipped from Test Deposit 3
  });

  test('Test Deposit empty json should process nothing', async () => {
    const vaultDepositApp = new VaultDepositApp();

    const resultEmpty: LoadDepositResult = await vaultDepositApp.loadDeposits(TEST_DEPOSIT_0_FILENAME);
    expect(resultEmpty.successes.length).toBe(0);
    expect(resultEmpty.fails.length).toBe(0);
    expect(resultEmpty.skipped.length).toBe(0);
  });
});
