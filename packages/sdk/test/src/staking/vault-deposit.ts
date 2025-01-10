import { CredbullFixedYieldVault, OwnableToken, OwnableToken__factory } from '@credbull/contracts';
import * as assert from 'assert';
import { BigNumber, Wallet, ethers } from 'ethers';

import { handleError } from '../utils/decoder';
import { logger, processedLogCache } from '../utils/logger';

import { Address, Deposit, DepositStatus, MAX_GAS_GWEI } from './deposit';

export class VaultDeposit extends Deposit {
  constructor(_id: number, _receiver: Address, _depositAmount: BigNumber) {
    super(_id, _receiver, _depositAmount);
  }

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

  async estimateGasForDeposit(vault: CredbullFixedYieldVault): Promise<BigNumber> {
    logger.debug(`Estimating gas for deposit [id=${this._id}] ...`);

    try {
      // Estimate gas
      const gasPrice = await vault.provider.getGasPrice(); // Gas price in Wei
      const gasEstimate = await vault.estimateGas.deposit(this._depositAmount, this._receiver);
      return this.estimateGas(gasPrice, gasEstimate);
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
      const gasPrice = await vault.provider.getGasPrice(); // Gas price in Wei
      const gasEstimate = await tokenAsOwner.estimateGas.approve(vault.address, this._depositAmount);
      return this.estimateGas(gasPrice, gasEstimate);
    } catch (err) {
      const decodedError = handleError(tokenAsOwner, err);
      logger.error('Gas estimation error for allowance:', decodedError.message);
      throw decodedError;
    }
  }
}
