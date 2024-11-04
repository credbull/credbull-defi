import { CredbullFixedYieldVault, CredbullFixedYieldVault__factory } from '@credbull/contracts';
import { Wallet, ethers, providers } from 'ethers';

import { Config, loadConfiguration } from '../utils/config';
import { logger } from '../utils/logger';

import { Address, DepositStatus, VaultDeposit } from './vault-deposit';
import { parseFromFile } from './vault-deposit-parser';

export class LoadDepositResult {
  successes: VaultDeposit[] = [];
  fails: VaultDeposit[] = [];
  skipped: VaultDeposit[] = [];

  logSummary(): string {
    return `Successes: ${this.successes.length}, Skipped: ${this.skipped.length}, Fails: ${this.fails.length}`;
  }
}

export class VaultDepositApp {
  private _config: Config;
  private _provider: providers.JsonRpcProvider;
  private _tokenOwner: Wallet;
  private _stakingVaultAddress: Address;

  constructor() {
    this._config = loadConfiguration();
    this._provider = new ethers.providers.JsonRpcProvider(this._config.services.ethers.url);
    this._stakingVaultAddress = this._config.evm.address.vault_cbl_staking;

    if (!this._config || !this._config.secret || !this._config.secret.DEPLOYER_PRIVATE_KEY) {
      throw new Error(`Deployer configuration and key not defined.`);
    }
    this._tokenOwner = new ethers.Wallet(this._config.secret.DEPLOYER_PRIVATE_KEY, this._provider);
  }

  async loadDeposits(filePath: string): Promise<LoadDepositResult> {
    logger.warn('******************');
    logger.warn('Starting Staking App');

    const result = new LoadDepositResult();

    const vault: CredbullFixedYieldVault = CredbullFixedYieldVault__factory.connect(
      this._stakingVaultAddress,
      this._tokenOwner,
    );

    // TODO - check if the tokenOwner has any tokens - no point in loading anything if not

    // parse the deposits
    const vaultDeposits: VaultDeposit[] = parseFromFile(filePath);

    logger.info('Begin Deposit all...');

    for (const deposit of vaultDeposits) {
      try {
        const status = await deposit.deposit(this._tokenOwner, vault);
        if (status === DepositStatus.Success) {
          result.successes.push(deposit);
          logger.info(`++ Deposit success: ${deposit.toString()}`);
        } else if (status === DepositStatus.SkippedAlreadyProcessed) {
          result.skipped.push(deposit);
          logger.info(`== Deposit skipped (already processed): ${deposit.toString()}`);
        }
      } catch (error) {
        logger.error(`-- Deposit failed !!!! ${deposit.toString()} .  Error: ${String(error)}`);
        throw error;
      }
    }

    logger.warn(`End Staking app.  Result: ' ${result.logSummary()}`);
    logger.warn('******************');

    return result;
  }
}

async function main() {
  const vaultDepositApp = new VaultDepositApp();
  const args = process.argv.slice(2); // Gets arguments after `--`
  const filePath = args[0] || 'TEST-vault-deposit-empty.json'; // default if no value is provided

  try {
    const result: LoadDepositResult = await vaultDepositApp.loadDeposits(filePath);
    logger.info(`Successfully loaded deposits!  Summary: ${result.logSummary()}`); // Log a summary after processing
  } catch (error) {
    logger.error('An error occurred while processing deposits:', error);
    throw error;
  }
}

// Execute main function if the file is run directly
main().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});
