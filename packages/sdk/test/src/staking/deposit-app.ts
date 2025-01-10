import { Wallet, ethers, providers } from 'ethers';

import { Config, loadConfiguration } from '../utils/config';
import { logger } from '../utils/logger';

import { Deposit, DepositStatus } from './deposit';
import { parseFromFile } from './deposit-parser';
import { VaultDeposit } from './vault-deposit';

export class LoadDepositResult {
  successes: Deposit[] = [];
  fails: Deposit[] = [];
  skipped: Deposit[] = [];

  logSummary(): string {
    return `Successes: ${this.successes.length}, Skipped: ${this.skipped.length}, Fails: ${this.fails.length}`;
  }
}

export abstract class DepositApp {
  protected _config: Config;
  protected _provider: providers.JsonRpcProvider;
  protected _tokenOwner: Wallet;

  constructor() {
    this._config = loadConfiguration();
    this._provider = new ethers.providers.JsonRpcProvider(this._config.services.ethers.url);

    if (!this._config || !this._config.secret || !this._config.secret.DEPLOYER_PRIVATE_KEY) {
      throw new Error(`Deployer configuration and key not defined.`);
    }
    this._tokenOwner = new ethers.Wallet(this._config.secret.DEPLOYER_PRIVATE_KEY, this._provider);
  }

  async loadDeposits(filePath: string): Promise<LoadDepositResult> {
    logger.warn('******************');
    logger.warn('Starting Staking App');

    const result = new LoadDepositResult();

    // parse the deposits
    const deposits: Deposit[] = parseFromFile(filePath, VaultDeposit);

    logger.info('Begin Deposit all...');

    for (const deposit of deposits) {
      try {
        const status = await this.deposit(deposit);

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

  abstract deposit(deposit: Deposit): Promise<DepositStatus>;
}
