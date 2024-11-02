import * as assert from 'assert';

import {
  CredbullFixedYieldVault,
  OwnableToken,
  OwnableToken__factory
} from '@credbull/contracts';
import {Wallet, ethers, BigNumber} from 'ethers';

import { Config, loadConfiguration } from '../utils/config';
import { handleError } from '../utils/decoder';

let config: Config;

type Address = string;

export class Deposit {
  constructor(
    private _id: number,
    private _owner: Wallet,
    private _receiver: Address,
    private _depositAmount: BigNumber,
  ) {}

  toString(): string {
    return `[Deposit ID: ${this._id}, Owner: ${this._owner.address}, Receiver: ${this._receiver}, Amount: ${this._depositAmount.toString()}]`;
  }

  async depositWithAllowance(vault: CredbullFixedYieldVault) {
    console.log('------------------');
    console.log(`Begin Deposit with Allowance ${this.toString()}`);

    await this.allowance(vault);
    await this.depositOnly(vault);

    console.log(`End Deposit with Allowance [id=${this._id}]`);
    console.log('------------------');
  }

  async depositOnly(vault: CredbullFixedYieldVault) {
    console.log(`Depositing [id=${this._id}] ...`);

    const prevVaultBalanceReceiver = await vault.balanceOf(this._receiver);

    // TODO - check if the same address will have multiple deposits. if not, we can skip any deposits that already exist.

    // now deposit
    // TODO - save the txn and grab the return value (shares)

    const depositTxnResponse = await vault.deposit(this._depositAmount, this._receiver).catch((err) => {
      const decodedError = handleError(vault, err);
      console.error('Deposit contract error:', decodedError.message);
      throw decodedError;
    });

    // wait for the transaction to be mined
    await depositTxnResponse.wait();

    const receiverBalance = await vault.balanceOf(this._receiver);
    const expectedBalance = this._depositAmount.add(prevVaultBalanceReceiver);
    assert.ok(
      expectedBalance.eq(receiverBalance),
      `Balance not correct!  Expected: ${expectedBalance} (${prevVaultBalanceReceiver} + ${this._depositAmount.toBigInt()}), but was: ${receiverBalance.toBigInt()}`,
    );

    console.log(`End Deposit Only [id=${this._id}].`);
  }

  async allowance(vault: CredbullFixedYieldVault) {
    const assetAddress: string = await vault.asset();
    const tokenAsOwner: OwnableToken = OwnableToken__factory.connect(assetAddress, this._owner);
    const ownerAddress = await this._owner.getAddress();

    const allowanceToGrant = this._depositAmount.sub(await tokenAsOwner.allowance(ownerAddress, vault.address));

    console.log(`Granting Allowance [id=${this._id}] ...`);

    if (allowanceToGrant.gt(ethers.BigNumber.from(0))) {
      console.log(`Approving staking vault [id=${this._id}] Allowance of: ${allowanceToGrant.toBigInt()}`);
      const approveTxnResponse = await tokenAsOwner.approve(vault.address, allowanceToGrant).catch((err) => {
        const decodedError = handleError(vault, err);
        console.error('Approval contract error:', decodedError.message);
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
      console.log(`Sufficient Allowance already exists [id=${this._id}]`);
    }
  }
}
