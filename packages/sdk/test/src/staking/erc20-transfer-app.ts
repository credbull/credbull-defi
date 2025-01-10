import { ERC20, ERC20__factory } from '@credbull/contracts';

import { logger } from '../utils/logger';

import { Address } from './deposit';
import { DepositApp, LoadDepositResult } from './deposit-app';
import { Erc20Transfer } from './erc20-transfer';

export class Erc20TransferApp extends DepositApp<Erc20Transfer> {
  private _address: Address;
  private _erc20: ERC20;

  constructor() {
    super();
    this._address = this._config.evm.address.cbl_token;

    this._erc20 = ERC20__factory.connect(this._address, this._signerWallet);
  }

  protected getDepositType() {
    return Erc20Transfer;
  }

  deposit(erc20transfer: Erc20Transfer) {
    return erc20transfer.deposit(this._signerWallet, this._erc20);
  }
}

async function main() {
  const vaultDepositApp = new Erc20TransferApp();
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
