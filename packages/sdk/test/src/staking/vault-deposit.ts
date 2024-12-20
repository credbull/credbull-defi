import { CredbullFixedYieldVault, OwnableToken, OwnableToken__factory } from '@credbull/contracts';
import * as assert from 'assert';
import { BigNumber, Wallet, ethers } from 'ethers';

import { handleError } from '../utils/decoder';
import { logger, processedLogCache, processedLogger } from '../utils/logger';

export type Address = string;

export enum DepositStatus {
  Success = 'Success',
  SkippedAlreadyProcessed = 'SkippedAlreadyProcessed',
}

const MAX_GAS_GWEI = BigInt(20000);
const ETH_PRICE_20241220 = BigInt(3300);

export class VaultDeposit {
  constructor(
    public readonly _id: number,
    public readonly _receiver: Address,
    public readonly _depositAmount: BigNumber,
  ) {}

  async deposit(owner: Wallet, vault: CredbullFixedYieldVault): Promise<DepositStatus> {
    logger.info('------------------');
    logger.info(`Begin Deposit ${this.toString()} from: ${owner.address}`);

    let depositStatus = undefined;

    const alreadyProcessed = await this.isProcessed(await owner.getChainId(), processedLogCache);
    if (alreadyProcessed) {
      depositStatus = DepositStatus.SkippedAlreadyProcessed;
    } else {
      await this.allowance(owner, vault);
      await this.depositOnly(vault);
      depositStatus = DepositStatus.Success;
    }

    logger.debug(`End Deposit [id=${this._id}]`);
    logger.info('------------------');
    return depositStatus;
  }

  async depositOnly(vault: CredbullFixedYieldVault) {
    logger.debug(`Depositing [id=${this._id}] ...`);

    const prevVaultBalanceReceiver = await vault.balanceOf(this._receiver);

    // TODO - check if the same address will have multiple deposits. if not, we can skip any deposits that already exist.

    // -------------------------- Simulate --------------------------

    const gasEstimate = await this.estimateGasForDeposit(vault);
    if (gasEstimate.toBigInt() > MAX_GAS_GWEI) {
      throw Error(
        `Gas Deposit (Deposit) [id=${this._id}] too high!  Gas= ${gasEstimate.toBigInt().toLocaleString()} gwei`,
      );
    }

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

    //const allowanceToGrant = this._depositAmount.sub(await tokenAsOwner.allowance(ownerAddress, vault.address));

    logger.debug(`Granting Allowance [id=${this._id}] ...`);

    const gasEstimate = await this.estimateGasForAllowance(owner, vault);
    if (gasEstimate.toBigInt() > MAX_GAS_GWEI) {
      throw Error(
        `Gas Deposit (Allowance) [id=${this._id}] too high!  Gas: ${gasEstimate.toBigInt().toLocaleString()} gwei`,
      );
    }

    const approveTxnResponse = await tokenAsOwner.approve(vault.address, this._depositAmount).catch((err) => {
      const decodedError = handleError(vault, err);
      logger.error('Approval contract error:', decodedError.message);
      throw decodedError;
    });

    // wait for the transaction to be mined
    await approveTxnResponse.wait();

    const allowance = await tokenAsOwner.allowance(ownerAddress, vault.address);
    assert.ok(
      this._depositAmount.gte(allowance),
      `Allowance not granted [id=${this._id}]. Expected: ${this._depositAmount.toString()}, but was: ${allowance.toString()}`,
    );
  }

  async estimateGas(vault: CredbullFixedYieldVault, gasEstimate: BigNumber): Promise<BigNumber> {
    try {
      // Estimate gas
      const gasPrice = await vault.provider.getGasPrice(); // Gas price in Wei
      const tnxCostInWei = gasEstimate.mul(gasPrice);
      const txnCostInGwei = tnxCostInWei.div(BigNumber.from(10).pow(9)); // Divide by 10^9

      const txnCostInEth = parseFloat(ethers.utils.formatEther(tnxCostInWei));
      const txnCostInUsd = txnCostInEth * Number(ETH_PRICE_20241220);

      logger.info(
        `Estimated gas for deposit [id=${this._id}]: ${txnCostInEth} ETH , ${txnCostInUsd} ( ${gasEstimate.toBigInt().toLocaleString()} * ${txnCostInGwei} gwei)`,
      );

      return txnCostInGwei;
    } catch (err) {
      const decodedError = handleError(vault, err);
      logger.error('Gas estimation error:', decodedError.message);
      throw decodedError;
    }
  }

  async estimateGasForDeposit(vault: CredbullFixedYieldVault): Promise<BigNumber> {
    logger.debug(`Estimating gas for deposit [id=${this._id}] ...`);

    try {
      // Estimate gas
      const gasEstimate = await vault.estimateGas.deposit(this._depositAmount, this._receiver);
      return this.estimateGas(vault, gasEstimate);
    } catch (err) {
      const decodedError = handleError(vault, err);
      logger.error('Gas estimation error:', decodedError.message);
      throw decodedError;
    }
  }

  async estimateGasForAllowance(owner: Wallet, vault: CredbullFixedYieldVault): Promise<BigNumber> {
    logger.debug(`Estimating gas for allowance [id=${this._id}] ...`);
    const assetAddress: string = await vault.asset();
    const tokenAsOwner: OwnableToken = OwnableToken__factory.connect(assetAddress, owner);

    try {
      // Get the asset address and connect the token as the owner
      const gasEstimate = await tokenAsOwner.estimateGas.approve(vault.address, this._depositAmount);
      return this.estimateGas(vault, gasEstimate);
    } catch (err) {
      const decodedError = handleError(tokenAsOwner, err);
      logger.error('Gas estimation error for allowance:', decodedError.message);
      throw decodedError;
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
