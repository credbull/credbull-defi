import { CredbullFixedYieldVault, OwnableToken, OwnableToken__factory } from '@credbull/contracts';
import * as assert from 'assert';
import { BigNumber, Wallet, ethers } from 'ethers';

import { handleError } from '../utils/decoder';
import { logger, processedLogCache, processedLogger } from '../utils/logger';

export type Address = string;

interface LoadDepositResult {
  processed: VaultDeposit[];
  skipped: VaultDeposit[];
}

export class VaultDeposit {
  constructor(
    public readonly _id: number,
    public readonly _receiver: Address,
    public readonly _depositAmount: BigNumber,
  ) {}

  static async depositAll(owner: Wallet, vault: CredbullFixedYieldVault, deposits: VaultDeposit[]) {
    logger.info('******************');
    logger.info('Begin DepositWithAllowance for all');

    for (const deposit of deposits) {
      try {
        await deposit.deposit(owner, vault);
      } catch (error) {
        logger.error(`!!!! Deposit failed !!!! ${deposit.toString()} .  Error: ${error.message}`);
      }
    }

    logger.info('End DepositWithAllowance for all');
    logger.info('******************');
  }

  async deposit(owner: Wallet, vault: CredbullFixedYieldVault) {
    logger.info('------------------');
    logger.info(`Begin Deposit from: ${owner.address} to: ${this.toString()}`);

    const alreadyProcessed = await this.isProcessed(await owner.getChainId(), processedLogCache);
    if (alreadyProcessed) {
      return;
    } else {
      await this.allowance(owner, vault);
      await this.depositOnly(vault);
    }
    logger.debug(`End Deposit [id=${this._id}]`);
  }

  async depositOnly(vault: CredbullFixedYieldVault) {
    logger.debug(`Depositing [id=${this._id}] ...`);

    const prevVaultBalanceReceiver = await vault.balanceOf(this._receiver);

    // TODO - check if the same address will have multiple deposits. if not, we can skip any deposits that already exist.

    // -------------------------- Simulate --------------------------

    // Simulate the deposit to get the return value (shares) without sending a transaction
    const shares = await vault.callStatic.deposit(this._depositAmount, this._receiver).catch((err) => {
      const decodedError = handleError(vault, err);
      logger.error('CallStatic deposit error:', decodedError.message);
      throw decodedError;
    });

    logger.debug(`Deposit simulated shares: ${shares.toString()}`);

    // -------------------------- Deposit --------------------------

    const depositTxnResponse = await vault.deposit(this._depositAmount, this._receiver).catch((err) => {
      const decodedError = handleError(vault, err);
      logger.error('Deposit contract error:', decodedError.message);
      throw decodedError;
    });

    // wait for the transaction to be mined
    const receipt = await depositTxnResponse.wait();
    logger.info(
      `Deposit Processed ${this.toString()} Txn status: ${receipt.status}  Txn hash: ${depositTxnResponse.hash}`,
    );
    await this.logResult(depositTxnResponse.chainId, depositTxnResponse.hash);

    const expectedBalance = this._depositAmount.add(prevVaultBalanceReceiver);
    const receiverBalance = await vault.balanceOf(this._receiver);
    if (!expectedBalance.eq(receiverBalance)) {
      logger.error(
        `!!!! Balance not correct after deposit [id=${this._id}]!!!!  Expected: ${expectedBalance} (${prevVaultBalanceReceiver} + ${this._depositAmount.toString()}), but was: ${receiverBalance.toString()}`,
      );
    }

    logger.debug(`End Deposit Only [id=${this._id}].`);
  }

  async allowance(owner: Wallet, vault: CredbullFixedYieldVault) {
    const assetAddress: string = await vault.asset();
    const tokenAsOwner: OwnableToken = OwnableToken__factory.connect(assetAddress, owner);
    const ownerAddress = await owner.getAddress();

    const allowanceToGrant = this._depositAmount.sub(await tokenAsOwner.allowance(ownerAddress, vault.address));

    logger.debug(`Granting Allowance [id=${this._id}] ...`);

    if (allowanceToGrant.gt(ethers.BigNumber.from(0))) {
      logger.debug(`Approving staking vault [id=${this._id}] Allowance of: ${allowanceToGrant.toBigInt()}`);
      const approveTxnResponse = await tokenAsOwner.approve(vault.address, allowanceToGrant).catch((err) => {
        const decodedError = handleError(vault, err);
        logger.error('Approval contract error:', decodedError.message);
        throw decodedError;
      });

      // wait for the transaction to be mined
      await approveTxnResponse.wait();

      const allowance = await tokenAsOwner.allowance(ownerAddress, vault.address);
      assert.ok(
        this._depositAmount.gte(allowance),
        `Allowance not granted [id=${this._id}]. Expected: ${allowanceToGrant.toString()}, but was: ${allowance.toString()}`,
      );
    } else {
      logger.debug(`Sufficient Allowance already exists [id=${this._id}]`);
    }
  }

  async isProcessed(chainId: number, processedLogMessages: any[]): Promise<boolean> {
    const alreadyProcessed = processedLogMessages.some(
      (entry) =>
        entry.message &&
        entry.message.chainId === chainId &&
        entry.message.VaultDeposit &&
        entry.message.VaultDeposit.id === this._id,
    );

    if (alreadyProcessed) {
      logger.debug(`Skipping VaultDeposit with id ${this._id} on chain ${chainId}.  Already processed.`);
    }

    return alreadyProcessed;
  }

  async logResult(chainId: number, txnHash: string, customLogger = processedLogger) {
    customLogger.info({
      chainId,
      ...this.toJson(), // Spread the JSON representation of the deposit
      txnHash, // Add the transaction hash
    });
  }

  toString(): string {
    return `VaultDeposit [id: ${this._id}, Receiver: ${this._receiver}, Amount: ${this._depositAmount.toString()}]`;
  }

  toJson(): object {
    return {
      VaultDeposit: {
        id: this._id,
        receiver: this._receiver,
        depositAmount: this._depositAmount.toString(), // Convert BigNumber to string for JSON serialization
      },
    };
  }
}
