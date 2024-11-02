import { CredbullFixedYieldVault__factory, ERC20__factory, OwnableToken__factory } from '@credbull/contracts';
import { expect, test } from '@playwright/test';
import { Wallet, ethers } from 'ethers';

import { Config, loadConfiguration } from '../utils/config';
import { handleError } from '../utils/decoder';
import { TestSigners } from '../utils/test-signer';

import { VaultDeposit } from './vault-deposit';

const VAULT_MAX_CAP = '10000000';

let provider: ethers.providers.JsonRpcProvider;
let config: Config;

let ownerSigner: Wallet;
let operatorSigner: Wallet;
let custodianSigner: Wallet;
let userSigner: Wallet;

let stakingVaultAddress: string;

test.beforeAll(async () => {
  config = loadConfiguration();
  provider = new ethers.providers.JsonRpcProvider(config.services.ethers.url);
  const testSigners: TestSigners = new TestSigners(provider);

  ownerSigner = testSigners.admin.getDelegate();
  operatorSigner = testSigners.operator.getDelegate();
  custodianSigner = testSigners.custodian.getDelegate();
  userSigner = testSigners.treasury.getDelegate();

  stakingVaultAddress = config.evm.address.vault_cbl_staking;
});

test.describe('Test Credbull Staking Challenge read operations', () => {
  test('Test read operations', async () => {
    const vault = await connectVault(stakingVaultAddress, userSigner);

    const token = await connectToken(await vault.asset(), userSigner);
    expect(token.decimals()).resolves.toEqual(18);

    // check the toggles
    expect(await vault.checkMaxCap()).toEqual(true);
    expect(await vault.checkWhiteList()).toEqual(true);

    // check the balances
    console.log('Owner CBL balance     = %s', (await token.balanceOf(ownerSigner.address)).toBigInt().toString());
    console.log('Operator CBL balance  = %s', (await token.balanceOf(operatorSigner.address)).toBigInt().toString());
    console.log('Custodian CBL balance = %s', (await token.balanceOf(custodianSigner.address)).toBigInt().toString());
    console.log('User CBL balance      = %s', (await token.balanceOf(userSigner.address)).toBigInt().toString());
    console.log('Vault CBL balance     = %s', (await token.balanceOf(vault.address)).toBigInt().toString());

    console.log('------------------ connected to vault ----------------');
    console.log(await vault.symbol());
    console.log('------------------ end ----------------');
  });
});

test.describe('Test Credbull Staking Challenge Owner updates', () => {
  test('Test turn off window checking', async () => {
    const vault = CredbullFixedYieldVault__factory.connect(stakingVaultAddress, ownerSigner);

    // turn off window checking
    if (await vault.checkWindow()) {
      await vault.toggleWindowCheck();
    } else {
      console.log('Window already toggled off, skipping');
    }

    expect(await vault.checkWindow()).toEqual(false); // now should be off
  });

  test('Update max cap to be the right precision', async () => {
    const maxcap = ethers.utils.parseEther(VAULT_MAX_CAP); // 10 million ETH in wei

    const vault = CredbullFixedYieldVault__factory.connect(stakingVaultAddress, ownerSigner);

    // check the asset
    const usdc = ERC20__factory.connect(await vault.asset(), ownerSigner);
    expect(usdc.decimals()).resolves.toEqual(18);

    const maxCap = await vault.maxCap();
    console.log('Vault maximum cap:', maxCap.toString());

    expect(await vault.checkMaxCap()).toEqual(true);
    console.log('maxcap=%s', (await vault.maxCap()).toBigInt());

    if ((await vault.maxCap()).toBigInt() != maxcap.toBigInt()) {
      console.log('Updating max cap...');
      await vault.updateMaxCap(maxcap); // update the max cap
    } else {
      console.log('Max cap already updated, skipping');
    }

    expect((await vault.maxCap()).toBigInt()).toEqual(maxcap.toBigInt()); // window starts on
  });
});

test.describe('Test Credbull Staking Challenge Vault Mint and Deposit', () => {
  const depositAmount = ethers.utils.parseEther('1000');

  test('Test Mint', async () => {
    const vaultAsUser = CredbullFixedYieldVault__factory.connect(stakingVaultAddress, userSigner);
    const assetAddress = await vaultAsUser.asset();
    const tokenAsUser = await connectToken(assetAddress, userSigner);

    // ------------------------- Mint -------------------------
    const userAddress = await userSigner.getAddress();
    await (await connectToken(assetAddress, operatorSigner)).mint(userAddress, depositAmount);

    expect((await tokenAsUser.balanceOf(userAddress)).toBigInt()).toBeGreaterThanOrEqual(depositAmount.toBigInt()); // window starts on
  });

  test('Test Deposit', async () => {
    const receiver = userSigner.address;

    const vaultAsUser = CredbullFixedYieldVault__factory.connect(stakingVaultAddress, userSigner);
    const prevVaultBalance = await vaultAsUser.balanceOf(receiver);

    const vaultDeposit: VaultDeposit = new VaultDeposit(1, receiver, depositAmount);
    await vaultDeposit.depositWithAllowance(userSigner, vaultAsUser);

    expect((await vaultAsUser.balanceOf(receiver)).toBigInt()).toEqual(
      prevVaultBalance.toBigInt() + depositAmount.toBigInt(),
    );
  });
});

test.describe('Test Credbull Staking Challenge Redeem', () => {
  test('Test turn off maturity checking', async () => {
    const vault = CredbullFixedYieldVault__factory.connect(stakingVaultAddress, ownerSigner);

    // turn off window checking
    if (await vault.checkMaturity()) {
      await vault.setMaturityCheck(false);
    } else {
      console.log('Maturity already off, skipping');
    }

    expect(await vault.checkMaturity()).toEqual(false); // now should be off
  });

  test('As Custodian, Move Assets into Vault', async () => {
    const vaultAsCustodian = CredbullFixedYieldVault__factory.connect(stakingVaultAddress, custodianSigner);
    const assetAddress = await vaultAsCustodian.asset();
    const tokenAsCustodian = await connectToken(assetAddress, custodianSigner);

    const tokenAsCustodianAddress = await custodianSigner.getAddress();
    const custodianBalance = await tokenAsCustodian.balanceOf(tokenAsCustodianAddress);

    console.log(
      'Transferring assets to vault as custodian %s balance of... ',
      await custodianSigner.address,
      custodianBalance.toBigInt(),
    );

    // now transfer
    await tokenAsCustodian.transfer(stakingVaultAddress, custodianBalance).catch((err) => {
      const decodedError = handleError(tokenAsCustodian, err);
      console.error('Transfer contract error:', decodedError.message);
      throw decodedError;
    });

    expect((await tokenAsCustodian.balanceOf(stakingVaultAddress)).toBigInt()).toBeGreaterThanOrEqual(
      custodianBalance.toBigInt(),
    );
    expect((await tokenAsCustodian.balanceOf(tokenAsCustodianAddress)).toNumber()).toEqual(0); // window starts on
  });

  test('Test Redeem', async () => {
    const vaultAsUser = CredbullFixedYieldVault__factory.connect(stakingVaultAddress, userSigner);

    const userAddress = await userSigner.getAddress();
    const prevUserBalance = await vaultAsUser.balanceOf(userAddress);

    // ------------------------- Deposit -------------------------
    console.log('Redeeming as user %s... ' + userAddress);

    const shares = await vaultAsUser.balanceOf(userAddress);

    // now redeem
    await vaultAsUser.redeem(shares, userAddress, userAddress).catch((err) => {
      const decodedError = handleError(vaultAsUser, err);
      console.error('Redeem contract error:', decodedError.message);
      throw decodedError;
    });

    const newUserBalance = await vaultAsUser.balanceOf(userAddress);
    const expectedBalance = prevUserBalance.sub(shares);
    console.log(
      'prevBalance=%s, newBalance=%s, expected=%s' + prevUserBalance.toBigInt(),
      newUserBalance.toBigInt(),
      expectedBalance.toBigInt(),
    );
    expect(newUserBalance.toBigInt()).toEqual(expectedBalance.toBigInt());
  });

  test('Test turn on maturity checking', async () => {
    const vault = CredbullFixedYieldVault__factory.connect(stakingVaultAddress, ownerSigner);

    // turn off window checking
    if (!(await vault.checkMaturity())) {
      await vault.setMaturityCheck(true);
    } else {
      console.log('Maturity already on, skipping');
    }

    expect(await vault.checkMaturity()).toEqual(true); // now should be off
  });
});

async function connectToken(assetAddress: string, wallet: Wallet) {
  console.log('Connecting to Token...');

  const token = OwnableToken__factory.connect(assetAddress, wallet);
  expect(token.decimals()).resolves.toEqual(18);

  const TOKEN_SYMBOL = config.node_env == 'development' ? 'SMPL' : 'CBL';
  expect(token.symbol()).resolves.toEqual(TOKEN_SYMBOL);

  console.log('Connected to Token! ' + (await token.symbol()));
  return token;
}

async function connectVault(vaultAddress: string, wallet: Wallet) {
  console.log('Connecting to vault...');

  const vault = CredbullFixedYieldVault__factory.connect(vaultAddress, wallet);
  expect(await vault.symbol()).toEqual('iceCBLsc');

  console.log('Connected to Vault! ' + (await vault.symbol()));

  return vault;
}
