import { CredbullFixedYieldVault__factory, ERC20__factory, OwnableToken__factory } from '@credbull/contracts';
import { expect, test } from '@playwright/test';
import { ethers } from 'ethers';

import { TestSigner, TestSigners } from './utils/test-signer';

const ANVIL_CONTRACT_ADDRESS = '0x0165878A594ca255338adfa4d48449f69242Eb8F';
const TOKEN_SYMBOL = 'SMPL'; // ANVIL - SMPL // TESTNET = CBL

let provider: ethers.providers.JsonRpcProvider;
let testSigners: TestSigners;
let userSigner: TestSigner;

test.beforeAll(async () => {
  provider = new ethers.providers.JsonRpcProvider(); // no url, defaults to 'http://localhost:8545'
  testSigners = new TestSigners(provider);
  userSigner = testSigners.alice;
});

test.describe('Test Credbull Staking Challenge read operations', () => {
  test('Test read operations', async () => {
    const liquidVault = CredbullFixedYieldVault__factory.connect(ANVIL_CONTRACT_ADDRESS, userSigner.getDelegate());

    // check state initialized
    expect(liquidVault.asset()).resolves.not.toEqual(ethers.constants.AddressZero);

    const token = await connectToken(await liquidVault.asset(), userSigner);

    // check the toggles
    expect(await liquidVault.checkMaturity()).toEqual(true);
    expect(await liquidVault.checkMaxCap()).toEqual(true);
    expect(await liquidVault.checkWhiteList()).toEqual(true);
  });
});

test.describe('Test Credbull Staking Challenge Owner updates', () => {
  test('Test turn off window checking', async () => {
    const adminSigner = testSigners.admin;

    const liquidVault = CredbullFixedYieldVault__factory.connect(ANVIL_CONTRACT_ADDRESS, adminSigner.getDelegate());

    // turn off window checking
    if (await liquidVault.checkWindow()) {
      await liquidVault.toggleWindowCheck();
    } else {
      console.log('Window already toggled off, skipping');
    }

    expect(await liquidVault.checkWindow()).toEqual(false); // now should be off
  });

  test('Test update max cap to be the right precision', async () => {
    const maxcap = ethers.utils.parseEther('10000000'); // 10 million ETH in wei

    const adminSigner = testSigners.admin;

    const liquidVault = CredbullFixedYieldVault__factory.connect(ANVIL_CONTRACT_ADDRESS, adminSigner.getDelegate());

    // check the asset
    const usdc = ERC20__factory.connect(await liquidVault.asset(), adminSigner.getDelegate());
    expect(usdc.decimals()).resolves.toEqual(18);

    // turn off window checking
    expect(await liquidVault.checkMaxCap()).toEqual(true); // window starts on
    console.log('maxcap=%s', (await liquidVault.maxCap()).toBigInt());

    if ((await liquidVault.maxCap()).toBigInt() != maxcap.toBigInt()) {
      console.log('Updating max cap...');
      await liquidVault.updateMaxCap(maxcap); // update the max cap
    } else {
      console.log('Max cap already updated, skipping');
    }

    expect((await liquidVault.maxCap()).toBigInt()).toEqual(maxcap.toBigInt()); // window starts on
  });
});

test.describe('Test Credbull Staking Challenge Mint and Deposit', () => {
  test('Mint and Deposit', async () => {
    const depositAmount = ethers.utils.parseEther('10000');

    const liquidVaultAsUser = CredbullFixedYieldVault__factory.connect(ANVIL_CONTRACT_ADDRESS, userSigner.getDelegate());
    const assetAddress = await liquidVaultAsUser.asset();
    const tokenAsUser = await connectToken(assetAddress, userSigner);

    // ------------------------- Mint -------------------------
    const minterSigner = testSigners.operator;
    const userAddress = await userSigner.getAddress();
    await (await connectToken(assetAddress, minterSigner)).mint(userAddress, depositAmount);

    expect((await tokenAsUser.balanceOf(userAddress)).toBigInt()).toBeGreaterThanOrEqual(depositAmount.toBigInt()); // window starts on

    // ------------------------- Deposit -------------------------
    // grant permission to vault to spend
    await tokenAsUser.approve(ANVIL_CONTRACT_ADDRESS, depositAmount);

    expect((await tokenAsUser.allowance(userAddress, ANVIL_CONTRACT_ADDRESS)).toBigInt()).toBeGreaterThanOrEqual(
      depositAmount.toBigInt()
    );

    const prevVaultBalance = await liquidVaultAsUser.balanceOf(userAddress);
    // now deposit
    await liquidVaultAsUser.deposit(depositAmount, userAddress);

    expect((await liquidVaultAsUser.balanceOf(userAddress)).toBigInt()).toEqual((prevVaultBalance.toBigInt() + depositAmount.toBigInt()));
  });
});

async function connectToken(assetAddress: string, minterSigner: TestSigner) {
  const token = OwnableToken__factory.connect(assetAddress, minterSigner.getDelegate());
  expect(token.decimals()).resolves.toEqual(18);
  expect(token.symbol()).resolves.toEqual(TOKEN_SYMBOL);
  return token;
}
