import { expect, test } from '@playwright/test';
import { BigNumber, Wallet, ethers } from 'ethers';

import { OWNER_PUBLIC_KEY_LOCAL, TestSigner, TestSigners } from './test-signer';

let provider: ethers.providers.JsonRpcProvider;
let testSigners: TestSigners;

test.beforeAll(async () => {
  provider = new ethers.providers.JsonRpcProvider(); // no url, defaults to 'http://localhost:8545'
  testSigners = new TestSigners(provider);
});

// See: https://github.com/safe-global/safe-core-sdk/tree/main/packages/protocol-kit
test.describe('Test signers', () => {
  test('Create a signer from the first account', async () => {
    const owner = new TestSigner(0, provider).getDelegate();

    expect(await owner.getAddress()).toEqual(OWNER_PUBLIC_KEY_LOCAL);
  });

  test('TestSigners signer address should be the first account', async () => {
    expect(await testSigners.admin.getAddress()).toEqual(OWNER_PUBLIC_KEY_LOCAL);
  });

  test('Admin signer sends 1 ETH', async () => {
    const depositAmount = ethers.utils.parseEther('1.0');

    // create a random wallet to receive the transfer
    const receivingWallet: Wallet = ethers.Wallet.createRandom();
    expect(await provider.getBalance(receivingWallet.address)).toEqual(BigNumber.from('0'));

    const adminSigner = testSigners.admin.getDelegate();
    const transactionResponse = await adminSigner.sendTransaction({
      to: receivingWallet.address,
      value: depositAmount,
    });

    await transactionResponse.wait(); // wait for the transaction to be mined

    expect(await provider.getBalance(receivingWallet.address)).toEqual(depositAmount);
  });
});
