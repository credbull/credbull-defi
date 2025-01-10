import { OwnableToken } from '@credbull/contracts';
import { BigNumber, Wallet } from 'ethers';

import { handleError } from '../utils/decoder';
import { logger, processedLogCache } from '../utils/logger';

import { Address, Deposit, DepositStatus } from './deposit';

export class Erc20Transfer extends Deposit {
  constructor(_id: number, _receiver: Address, _depositAmount: BigNumber) {
    super(_id, _receiver, _depositAmount);
  }

  async deposit(owner: Wallet, erc20: OwnableToken): Promise<DepositStatus> {
    logger.info('------------------');
    logger.info(`Begin Transfer ${this.toString()} from: ${owner.address}`);

    let depositStatus = undefined;

    const alreadyProcessed = await this.isProcessed(await owner.getChainId(), processedLogCache);
    if (alreadyProcessed) {
      depositStatus = DepositStatus.SkippedAlreadyProcessed;
    } else {
      await this.transferOnly(erc20);
      depositStatus = DepositStatus.Success;
    }

    logger.debug(`End Transfer [id=${this._id}]`);
    logger.info('------------------');
    return depositStatus;
  }

  async transferOnly(erc20: OwnableToken) {
    logger.debug(`Transferring [id=${this._id}] ...`);

    const prevVaultBalanceReceiver = await erc20.balanceOf(this._receiver);

    const txnResponse = await erc20.transfer(this._receiver, this._depositAmount).catch((err) => {
      const decodedError = handleError(erc20, err);
      logger.error('Transfer contract error:', decodedError.message);
      throw decodedError;
    });

    // wait for the transaction to be mined
    const receipt = await txnResponse.wait();
    logger.info(`Transfer Processed ${this.toString()} Txn status: ${receipt.status}  Txn hash: ${txnResponse.hash}`);
    await this.logResult(txnResponse.chainId, txnResponse.hash);

    const expectedBalance = this._depositAmount.add(prevVaultBalanceReceiver);
    const receiverBalance = await erc20.balanceOf(this._receiver);
    if (!expectedBalance.eq(receiverBalance)) {
      logger.error(
        `!!!! Balance not correct after transfer [id=${this._id}]!!!!  Expected: ${expectedBalance} (${prevVaultBalanceReceiver} + ${this._depositAmount.toString()}), but was: ${receiverBalance.toString()}`,
      );
    }

    logger.debug(`End Transfer Only [id=${this._id}].`);
  }
}
