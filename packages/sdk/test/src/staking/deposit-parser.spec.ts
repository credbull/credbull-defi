import { expect, test } from '@playwright/test';
import { ethers } from 'ethers';

import { parseFromFile } from './deposit-parser';
import { VaultDeposit } from './vault-deposit';

const TEST_DEPOSIT_3_FILENAME = 'TEST-deposit-3.json';

test.describe('Test Deposit loader', () => {
  test('Test parse from file', async () => {
    const deposits: VaultDeposit[] = parseFromFile(TEST_DEPOSIT_3_FILENAME, VaultDeposit);
    expect(deposits.length).toBeGreaterThanOrEqual(1);

    for (const deposit of deposits) {
      expect(deposit._id).toBeGreaterThanOrEqual(1);
      expect(deposit._depositAmount.toBigInt()).toBeGreaterThanOrEqual(BigInt(1e18));
      expect(deposit._receiver).not.toBeNull();
      expect(ethers.utils.isAddress(deposit._receiver)).toBe(true);
    }
  });
});
