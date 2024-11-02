import { CredbullFixedYieldVault__factory } from '@credbull/contracts';
import { test } from '@playwright/test';
import { Wallet, ethers } from 'ethers';

import { Config, loadConfiguration } from '../utils/config';
import { TestSigners } from '../utils/test-signer';

import { VaultDeposit } from './vault-deposit';
import { parseFromFile } from './vault-depost-parser';

let config: Config;

test.beforeAll(async () => {
  config = loadConfiguration();
});

test.describe('Test Vault Deposit for all', () => {
  test('Test Deposit for all', async () => {
    const provider = new ethers.providers.JsonRpcProvider(config.services.ethers.url);
    const tokenOwner: Wallet = new TestSigners(provider).treasury.getDelegate();
    const stakingVaultAddress = config.evm.address.vault_cbl_staking;

    // parse the deposits
    const vaultDeposits: VaultDeposit[] = parseFromFile('TEST-staking-data.json');

    // now deposit all
    const vault = CredbullFixedYieldVault__factory.connect(stakingVaultAddress, tokenOwner);
    await VaultDeposit.depositWithAllowanceForAll(tokenOwner, vault, vaultDeposits);
  });
});
