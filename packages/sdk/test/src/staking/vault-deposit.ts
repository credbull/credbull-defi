import { CredbullFixedYieldVault, OwnableToken, OwnableToken__factory } from '@credbull/contracts';
import * as assert from 'assert';
import { BigNumber, Wallet, ethers } from 'ethers';

import { handleError } from '../utils/decoder';
import logger from '../utils/logger';

type Address = string;

export class VaultDeposit {
  constructor(
    public readonly _id: number,
    public readonly _receiver: Address,
    public readonly _depositAmount: BigNumber,
  ) {}

  toString(): string {
    return `VaultDeposit [id: ${this._id}, Receiver: ${this._receiver}, Amount: ${this._depositAmount.toString()}]`;
  }

  async depositWithAllowance(owner: Wallet, vault: CredbullFixedYieldVault) {
    logger.debug('------------------');
    logger.info(`Begin Deposit from: ${owner.address} to: ${this.toString()}`);

    await this.allowance(owner, vault);
    await this.depositOnly(vault);

    logger.debug(`End Deposit [id=${this._id}]`);
    logger.debug('------------------');
  }

  async depositOnly(vault: CredbullFixedYieldVault) {
    logger.debug(`Depositing [id=${this._id}] ...`);

    const prevVaultBalanceReceiver = await vault.balanceOf(this._receiver);

    // TODO - check if the same address will have multiple deposits. if not, we can skip any deposits that already exist.
    // TODO - save the txn and grab the return value (shares)

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
    logger.info(`Deposit Txn ${this.toString()} Txn status: ${receipt.status}  Txn hash: ${depositTxnResponse.hash}`);

    const receiverBalance = await vault.balanceOf(this._receiver);
    const expectedBalance = this._depositAmount.add(prevVaultBalanceReceiver);
    assert.ok(
      expectedBalance.eq(receiverBalance),
      `Balance not correct!  Expected: ${expectedBalance} (${prevVaultBalanceReceiver} + ${this._depositAmount.toBigInt()}), but was: ${receiverBalance.toBigInt()}`,
    );

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
}
