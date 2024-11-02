import { CredbullFixedYieldVault__factory } from '@credbull/contracts';
import { expect, test } from '@playwright/test';
import { BigNumber, Wallet, ethers } from 'ethers';

import { Config, loadConfiguration } from '../utils/config';
import { TestSigners } from '../utils/test-signer';

import { VaultDeposit } from './vault-deposit';
import { parseFromFile } from './vault-depost-parser';
import { processedLogger, processedLogCache } from '../utils/logger'; // Import processedLogger and logMessages

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

test.describe('Test VaultDeposit Utility functions', () => {
  const vaultDeposit = new VaultDeposit(
    15,
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

    // Clear logMessages array before starting the test
    processedLogCache.length = 0;

    expect(await vaultDeposit.isProcessed(chainId, processedLogCache)).toBe(false); // Nothing logged, should NOT be processed

    // Act: Call logResult using the real processedLogger
    const txnHash = '0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef';
    await vaultDeposit.logResult(chainId, txnHash, processedLogger);

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
