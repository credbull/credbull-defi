import { BigNumber, ethers } from 'ethers';

import { logger, processedLogger } from '../utils/logger';

export type Address = string;

export enum DepositStatus {
  Success = 'Success',
  SkippedAlreadyProcessed = 'SkippedAlreadyProcessed',
}

const MAX_GAS_GWEI = BigInt(20_000);
export const ETH_PRICE_20241220 = BigInt(3300);

export class Deposit {
  constructor(
    public readonly _id: number,
    public readonly _receiver: Address,
    public readonly _depositAmount: BigNumber,
  ) {}

  async logResult(chainId: number, txnHash: string, customLogger = processedLogger) {
    customLogger.info({
      chainId,
      ...this.toJson(), // Spread the JSON representation of the deposit
      txnHash, // Add the transaction hash
    });
  }

  toString(): string {
    return `Deposit [id: ${this._id}, Receiver: ${this._receiver}, Amount: ${this._depositAmount.toString()}]`;
  }

  toJson(): object {
    return {
      Deposit: {
        id: this._id,
        receiver: this._receiver,
        depositAmount: this._depositAmount.toString(), // Convert BigNumber to string for JSON serialization
      },
    };
  }

  async isProcessed(chainId: number, processedLogMessages: any[]): Promise<boolean> {
    const alreadyProcessed = processedLogMessages.some(
      (entry) =>
        entry.message &&
        entry.message.chainId === chainId &&
        entry.message.Deposit &&
        entry.message.Deposit.id === this._id,
    );

    if (alreadyProcessed) {
      logger.debug(`Skipping Deposit with id ${this._id} on chain ${chainId}.  Already processed.`);
    }

    return alreadyProcessed;
  }

  estimateGas(gasPrice: BigNumber, gasEstimate: BigNumber): BigNumber {
    // Estimate gas
    const tnxCostInWei = gasEstimate.mul(gasPrice);
    const txnCostInGwei = tnxCostInWei.div(BigNumber.from(10).pow(9)); // Divide by 10^9

    const txnCostInEth = parseFloat(ethers.utils.formatEther(tnxCostInWei));
    const txnCostInUsd = txnCostInEth * Number(ETH_PRICE_20241220);

    logger.info(
      `Estimated gas for deposit [id=${this._id}]: ${txnCostInEth} ETH , ${txnCostInUsd} ( ${gasEstimate.toBigInt().toLocaleString()} * ${txnCostInGwei} gwei)`,
    );

    return txnCostInGwei;
  }
}
