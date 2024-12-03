import { ERC20__factory, LiquidContinuousMultiTokenVault__factory } from '@credbull/contracts';
import { expect, test } from '@playwright/test';
import { BigNumber, ethers } from 'ethers';

import { TestSigners } from './utils/test-signer';

let provider: ethers.providers.JsonRpcProvider;
let testSigners: TestSigners;

test.beforeAll(async () => {
  provider = new ethers.providers.JsonRpcProvider(); // no url, defaults to 'http://localhost:8545'
  testSigners = new TestSigners(provider);
});

const VAULT_PROXY_CONTRACT_ADDRESS = '0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9';

test.describe.skip('Test LiquidContinuousMultiTokenVault ethers operations', () => {
  test('Test read operations', async () => {
    const user = testSigners.alice;

    const liquidVault = LiquidContinuousMultiTokenVault__factory.connect(
      VAULT_PROXY_CONTRACT_ADDRESS,
      user.getDelegate(),
    );

    const blockNumber = provider.getBlockNumber();
    const block = await provider.getBlock(blockNumber);

    // check state initialized
    expect(liquidVault.asset()).resolves.not.toEqual(ethers.constants.AddressZero);
    expect(liquidVault._yieldStrategy()).resolves.not.toEqual(ethers.constants.AddressZero);
    expect(liquidVault._redeemOptimizer()).resolves.not.toEqual(ethers.constants.AddressZero);
    expect(liquidVault._vaultStartTimestamp()).resolves.not.toEqual(ethers.constants.AddressZero);

    // check the asset
    const usdc = ERC20__factory.connect(await liquidVault.asset(), user.getDelegate());
    expect(usdc.symbol()).resolves.toEqual('sUSDC');

    // check some behavior
    const expectedTenor = 30;
    expect(liquidVault._vaultStartTimestamp().then((ts) => ts.toNumber())).resolves.toBeLessThanOrEqual(
      block.timestamp,
    );
    expect(liquidVault.TENOR()).resolves.toEqual(BigNumber.from(expectedTenor));

    const vaultStartTimestamp = (await liquidVault._vaultStartTimestamp()).toNumber();
    console.log('Vault StarTime:', new Date(vaultStartTimestamp * 1000).toUTCString());

    expect(liquidVault['totalSupply()']().then((ts) => ts.toNumber())).resolves.toBeGreaterThanOrEqual(
      BigNumber.from(0).toNumber(),
    );

    expect(liquidVault.currentPeriod()).resolves.toEqual(BigNumber.from(expectedTenor));
  });

  test('Redeem a redeemRequest', async () => {
    const user = testSigners.alice;
    const redeemPeriod = BigNumber.from(30).toNumber(); // redeemPeriod and requestId are equal

    const liquidVault = LiquidContinuousMultiTokenVault__factory.connect(
      VAULT_PROXY_CONTRACT_ADDRESS,
      user.getDelegate(),
    );
    const userAddress = await user.getAddress();

    // unlock requests
    const unlockRequestAmount = (await liquidVault.unlockRequestAmount(userAddress, redeemPeriod)).toNumber();

    if (unlockRequestAmount > 0) {
      console.log('Redeeming for redeemPeriod = %s ...', redeemPeriod);

      await liquidVault.redeem(unlockRequestAmount, userAddress, userAddress);

      // verify unlock succeeded
      expect((await liquidVault.unlockRequestAmount(userAddress, redeemPeriod)).toNumber()).toEqual(0);
    }
  });

  test('Release a redeemRequest without redeeming', async () => {
    const user = testSigners.alice;
    const redeemPeriod = BigNumber.from(30).toNumber(); // redeemPeriod and requestId are equal

    const liquidVault = LiquidContinuousMultiTokenVault__factory.connect(
      VAULT_PROXY_CONTRACT_ADDRESS,
      user.getDelegate(),
    );
    const userAddress = await user.getAddress();

    const unlockRequestAmount = (await liquidVault.unlockRequestAmount(userAddress, redeemPeriod)).toNumber();

    if (unlockRequestAmount > 0) {
      console.log('Releasing requestRedeem without redeeming for redeemPeriod = %s ...', redeemPeriod);

      // unlocks does NOT redeem.  it only deletes the request.
      await liquidVault.unlock(userAddress, BigNumber.from(redeemPeriod).toNumber());

      // verify unlock succeeded
      expect((await liquidVault.unlockRequestAmount(userAddress, redeemPeriod)).toNumber()).toEqual(0);
    }
  });
});
