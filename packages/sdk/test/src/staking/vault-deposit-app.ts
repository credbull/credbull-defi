import { CredbullFixedYieldVault, CredbullFixedYieldVault__factory } from '@credbull/contracts';
import { Wallet, ethers, providers } from 'ethers';

import { Config, loadConfiguration } from '../utils/config';
import { logger } from '../utils/logger';

import { Address, DepositStatus, VaultDeposit } from './vault-deposit';
import { parseFromFile } from './vault-depost-parser';

export class LoadDepositResult {
  successes: VaultDeposit[] = [];
  fails: VaultDeposit[] = [];
  skipped: VaultDeposit[] = [];

  logSummary() {
    logger.info(`Successes: ${this.successes.length}, Skipped: ${this.skipped.length}, Fails: ${this.fails.length}`);
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
    this._tokenOwner = new ethers.Wallet(this._config.secret.ALICE_PRIVATE_KEY, this._provider);
  }

  async loadDeposits(filePath: string): Promise<LoadDepositResult> {
    logger.info('******************');
    logger.info('Starting Staking App');

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
        logger.error(`-- Deposit failed !!!! ${deposit.toString()} .  Error: ${error.message}`);
        throw error;
      }
    }

    logger.info('End Staking app');
    logger.info('******************');

    return result;
  }
}
