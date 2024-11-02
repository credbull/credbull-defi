import { expect, test } from '@playwright/test';
import { ethers } from 'ethers';

import { VaultDeposit } from './vault-deposit';
import { parseFromFile } from './vault-depost-parser';

test.describe('Test Vault Deposit loader', () => {
  test('Test parse from file', async () => {
    const vaultDeposits: VaultDeposit[] = parseFromFile('TEST-staking-data.json');
    expect(vaultDeposits.length).toBeGreaterThanOrEqual(1);

    for (const vaultDeposit of vaultDeposits) {
      expect(vaultDeposit._id).toBeGreaterThanOrEqual(1);
      expect(vaultDeposit._depositAmount.toBigInt()).toBeGreaterThanOrEqual(BigInt(1e18));
      expect(vaultDeposit._receiver).not.toBeNull();
      expect(ethers.utils.isAddress(vaultDeposit._receiver)).toBe(true);
    }
  });
});
