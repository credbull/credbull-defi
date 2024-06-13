import { expect, test } from '@playwright/test';
import { Wallet, ethers } from 'ethers';

import { CredbullSDK } from '../../../src';

import { login } from './admin';
import { OWNER_PUBLIC_KEY_LOCAL, TestSigner, TestSigners } from './test-signer';

let provider: ethers.providers.JsonRpcProvider;

let config: any = {
  api: {
    url: 'http://127.0.0.1:3001',
  },
  services: {
    ethers: {
      url: 'http://127.0.0.1:8545',
    },
  },
};

let testSigners: TestSigners;

async function userFor(name: string, email: string, password: string, privateKey: string, testSigner: TestSigner) {
  const { access_token: accessToken, user_id } = await login(email, password);

  const wallet = new Wallet(privateKey, new ethers.providers.JsonRpcProvider(config.services.ethers.url));
  const address = await wallet.getAddress();

  // const sdk = new CredbullSDK(config.api.url, { accessToken }, wallet);
  const sdk = new CredbullSDK(config.api.url, { accessToken }, testSigner.getDelegate());
  return { name, email, password, id: user_id, accessToken, wallet, address, testSigner, sdk };
}

/*
 we don't need to pass in the private key and a TestSigner.  the TestSigner is a wallet.
 */
async function userForNew(name: string, email: string, password: string, testSigner: TestSigner) {
  const { access_token: accessToken, user_id } = await login(email, password);

  const sdk = new CredbullSDK(config.api.url, { accessToken }, testSigner.getDelegate());

  return { name, email, password, id: user_id, accessToken, testSigner, sdk };
}

test.beforeAll(async () => {
  provider = new ethers.providers.JsonRpcProvider(); // no url, defaults to ``http:/\/localhost:8545`
  testSigners = new TestSigners(provider);
});

// See: https://github.com/safe-global/safe-core-sdk/tree/main/packages/protocol-kit
test.describe('Test Create SDK', () => {
  test('Create a signer from the first account', async () => {
    const owner = new TestSigner(0, provider).getDelegate();

    expect(await owner.getAddress()).toEqual(OWNER_PUBLIC_KEY_LOCAL);
  });

  test('Test userFor', async () => {
    const nameArg = 'alice';
    const emailArg = 'test+alice@credbull.io';
    const passwordArg = 'alice-1234';

    const privateKeyArg = '0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356';

    const { sdk: sdk } = await userFor(nameArg, emailArg, passwordArg, privateKeyArg, testSigners.alice);
    const sdkLinkResult = await sdk.linkWallet();
    expect(sdkLinkResult.address).toEqual(await testSigners.alice.getAddress());

    // called without the private key - we already have alice as a signer
    const { sdk: sdkNew } = await userForNew(nameArg, emailArg, passwordArg, testSigners.alice);
    const sdkNewLinkResult = await sdkNew.linkWallet();
    expect(sdkNewLinkResult.address).toEqual(await testSigners.alice.getAddress());
  });
});
