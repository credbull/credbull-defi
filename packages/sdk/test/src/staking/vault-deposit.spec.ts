import { CredbullFixedYieldVault__factory } from '@credbull/contracts';
import { expect, test } from '@playwright/test';
import { BigNumber, Wallet, ethers } from 'ethers';
import { PassThrough } from 'stream';
import * as winston from 'winston';

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

test.describe('Test VaultDeposit Helper functions', () => {
  const vaultDeposit = new VaultDeposit(
    7,
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

  test('should log VaultDeposit as json including txn hash', async () => {
    // Create a mock logger using Winston
    const logMessages: any[] = [];
    const logStream = new PassThrough();
    logStream.on('data', (chunk) => {
      logMessages.push(JSON.parse(chunk.toString())); // Parse JSON log entry and store it
    });
    const mockLogger = winston.createLogger({
      level: 'info',
      format: winston.format.json(),
      transports: [new winston.transports.Stream({ stream: logStream })],
    });

    // Act: Call logResult with the mock logger
    const txnHash = '0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef';
    const chainId = 31137;
    await vaultDeposit.logResult(chainId, txnHash, mockLogger);

    expect(logMessages[0]).toEqual({
      level: 'info',
      message: {
        chainId: chainId,
        txnHash: txnHash,
        ...vaultDeposit.toJson(),
      },
    });

    console.log(`LogMessage: ${JSON.stringify(logMessages[0], null, 2)}`);
  });
});
