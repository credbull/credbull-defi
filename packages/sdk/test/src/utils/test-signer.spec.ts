import { expect, test } from '@playwright/test';
import { BigNumber, Wallet, ethers } from 'ethers';

import { Config, loadConfiguration } from './config';
import { TestSigner, TestSigners } from './test-signer';

let provider: ethers.providers.JsonRpcProvider;
let testSigners: TestSigners;
let config: Config;

test.beforeAll(async () => {
  config = loadConfiguration();

  provider = new ethers.providers.JsonRpcProvider(config.services.ethers.url);
  testSigners = new TestSigners(provider);
});

// See: https://github.com/safe-global/safe-core-sdk/tree/main/packages/protocol-kit
test.describe('Test signers', () => {
  test('TestSigners admin should be the first account', async () => {
    const ownerWallet = new ethers.Wallet(config.secret.ADMIN_PRIVATE_KEY, provider);

    const owner = new TestSigner(0, provider).getDelegate();

    expect(await owner.getAddress()).toEqual(ownerWallet.address);
    expect(await testSigners.admin.getAddress()).toEqual(ownerWallet.address);
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
