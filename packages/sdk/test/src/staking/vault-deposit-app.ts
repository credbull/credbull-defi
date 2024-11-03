import { CredbullFixedYieldVault, CredbullFixedYieldVault__factory } from '@credbull/contracts';
import { Wallet, ethers, providers } from 'ethers';

import { Config, loadConfiguration } from '../utils/config';
import { logger } from '../utils/logger';

import { Address, VaultDeposit } from './vault-deposit';
import { parseFromFile } from './vault-depost-parser';

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

  async loadDeposits(filePath: string) {
    logger.info('******************');
    logger.info('Starting Staking App');

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
        await deposit.deposit(this._tokenOwner, vault);
        logger.error(`++ Deposit success !!!! ${deposit.toString()}`);

      } catch (error) {
        logger.error(`-- Deposit failed !!!! ${deposit.toString()} .  Error: ${error.message}`);
        throw error;
      }
    }

    logger.info('End Staking app');
    logger.info('******************');
  }
}
