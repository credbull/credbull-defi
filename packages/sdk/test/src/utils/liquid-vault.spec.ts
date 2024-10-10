import { ERC20__factory, LiquidContinuousMultiTokenVault__factory } from '@credbull/contracts';
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
test.describe.skip('Test reading contracts', () => {
  test('Create a signer from the first account', async () => {
    const owner = new TestSigner(0, provider).getDelegate();

    expect(await owner.getAddress()).toEqual(OWNER_PUBLIC_KEY_LOCAL);
  });

  test('Test read operations', async () => {
    // const vaultProxyAddress = '0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9'; // without data
    const vaultProxyAddress = '0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9'; // with data

    const liquidVault = LiquidContinuousMultiTokenVault__factory.connect(
      vaultProxyAddress,
      testSigners.admin.getDelegate(),
    );

    const blockNumber = provider.getBlockNumber();
    const block = await provider.getBlock(blockNumber);

    // check state initialized
    expect(liquidVault.asset()).resolves.not.toEqual(ethers.constants.AddressZero);
    expect(liquidVault._yieldStrategy()).resolves.not.toEqual(ethers.constants.AddressZero);
    expect(liquidVault._redeemOptimizer()).resolves.not.toEqual(ethers.constants.AddressZero);
    expect(liquidVault._vaultStartTimestamp()).resolves.not.toEqual(ethers.constants.AddressZero);

    // check the asset
    const usdc = ERC20__factory.connect(await liquidVault.asset(), testSigners.admin.getDelegate());
    expect(usdc.symbol()).resolves.toEqual('sUSDC');

    // check some behavior
    const expectedTenor = 30;
    expect(liquidVault._vaultStartTimestamp().then(ts => ts.toNumber())).resolves.toBeLessThanOrEqual(block.timestamp);
    expect(liquidVault.TENOR()).resolves.toEqual(BigNumber.from(expectedTenor));

    // won't work with data loaded version
    expect(liquidVault['totalSupply()']().then(ts => ts.toNumber())).resolves.toBeGreaterThanOrEqual(BigNumber.from(0).toNumber());
    expect(liquidVault.currentPeriod()).resolves.toEqual(BigNumber.from(expectedTenor));
  });
});
