// Multi user deposit test similar to deposit.spec.ts
import { expect, test } from '@playwright/test';
import { config } from 'dotenv';
import { BigNumber, Signer } from 'ethers';

import { CredbullSDK } from '../index';
import { signer } from '../mock/utils/helpers';

import {
  __mockMint,
  createFixedYieldVault,
  distributeFixedYieldVault,
  getVaultEntities,
  login,
  toggleWindowCheck,
  whitelist,
} from './utils/admin-ops';

config();

let walletSignerA: Signer | undefined = undefined;
let walletSignerB: Signer | undefined = undefined;
let operatorSigner: Signer | undefined = undefined;
let custodianSigner: Signer | undefined = undefined;

let sdkA: CredbullSDK;
let sdkB: CredbullSDK;

let userAddressA: string;
let userAddressB: string;

let userAId: string;
let userBId: string;

let vaultAddress: string[];

test.beforeAll(async () => {
  const { access_token: userAToken, user_id: _userAId } = await login(
    process.env.USER_A_EMAIL || '',
    process.env.USER_A_PASSWORD || '',
  );
  const { access_token: userBToken, user_id: _userBId } = await login(
    process.env.USER_B_EMAIL || '',
    process.env.USER_B_PASSWORD || '',
  );

  walletSignerA = signer(process.env.USER_A_PRIVATE_KEY || '0x');
  walletSignerB = signer(process.env.USER_B_PRIVATE_KEY || '0x');
  operatorSigner = signer(process.env.OPERATOR_PRIVATE_KEY || '0x');
  custodianSigner = signer(process.env.CUSTODIAN_PRIVATE_KEY || '0x');

  sdkA = new CredbullSDK(userAToken, walletSignerA as Signer);
  sdkB = new CredbullSDK(userBToken, walletSignerB as Signer);

  userAddressA = await (walletSignerA as Signer).getAddress();
  userAddressB = await (walletSignerB as Signer).getAddress();

  userAId = _userAId;
  userBId = _userBId;

  //link wallet
  await sdkA.linkWallet();
  await sdkB.linkWallet();
});

test.describe('Claim yield and principal - Fixed', async () => {
  test('create vault', async () => {
    await createFixedYieldVault();
    await createFixedYieldVault();
  });

  test('Whitelist users', async () => {
    await whitelist(userAddressA, userAId);
    await whitelist(userAddressB, userBId);
  });

  test('Deposit to the vault', async () => {
    const depositAmount = BigNumber.from('1000000000');

    vaultAddress = await test.step('Get all vaults', async () => {
      const vaults = await sdkA.getAllVaults();
      const totalVaults = vaults.data.length;

      expect(totalVaults).toBeGreaterThan(0);
      expect(vaults).toBeTruthy();

      const fixedYieldVaults = vaults.data.filter((vault: any) => vault.type === 'fixed_yield');

      //sort by created_at
      fixedYieldVaults.sort((a: any, b: any) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime());
      expect(fixedYieldVaults).toBeTruthy();

      return [
        fixedYieldVaults[fixedYieldVaults.length - 1].address,
        fixedYieldVaults[fixedYieldVaults.length - 2].address,
      ];
    });

    await test.step('Empty custodian', async () => {
      for (let i = 0; i < vaultAddress.length; i++) {
        const vault = await sdkA.getVaultInstance(vaultAddress[i]);
        const usdc = await sdkA.getAssetInstance(vaultAddress[i]);
        const custodian = await vault.CUSTODIAN();
        const custodianBalance = await usdc.balanceOf(custodian);
        console.log('custodian balance', custodianBalance.toString());
        console.log('signer address', await custodianSigner?.getAddress());
        if (custodianBalance.gt(0))
          usdc
            .connect(custodianSigner as Signer)
            .transfer('0xcabE80b332Aa9d900f5e32DF51cb0Bc5b276c556', custodianBalance);
        console.log('custodian address', custodian);
        console.log('custodian balance', (await usdc.balanceOf(custodian)).toString());
      }
    });

    await test.step('MINT USDC for user', async () => {
      for (let i = 0; i < vaultAddress.length; i++) {
        const vault = await sdkA.getVaultInstance(vaultAddress[i]);

        await __mockMint(userAddressA, depositAmount, vault, walletSignerA as Signer);
        await __mockMint(userAddressB, depositAmount, vault, walletSignerB as Signer);
      }
    });

    await test.step('Approve USDC', async () => {
      for (let i = 0; i < vaultAddress.length; i++) {
        const usdc = await sdkA.getAssetInstance(vaultAddress[i]);
        await usdc.connect(walletSignerA as Signer).approve(vaultAddress[i], depositAmount);
        await usdc.connect(walletSignerB as Signer).approve(vaultAddress[i], depositAmount);
      }
    });

    await test.step('Deposit to the vault', async () => {
      for (let i = 0; i < vaultAddress.length; i++) {
        await sdkA.deposit(vaultAddress[i], depositAmount, userAddressA);
        await sdkB.deposit(vaultAddress[i], depositAmount, userAddressB);
      }
    });
  });

  test('Distributioin of yield', async () => {
    vaultAddress = await test.step('Get all vaults', async () => {
      const vaults = await sdkA.getAllVaults();
      const totalVaults = vaults.data.length;

      expect(totalVaults).toBeGreaterThan(0);
      expect(vaults).toBeTruthy();

      const fixedYieldVaults = vaults.data.filter((vault: any) => vault.type === 'fixed_yield');
      expect(fixedYieldVaults).toBeTruthy();

      return [
        fixedYieldVaults[fixedYieldVaults.length - 1].address,
        fixedYieldVaults[fixedYieldVaults.length - 2].address,
      ];
    });

    const vaults = await sdkA.getAllVaults();

    let treasuryAddresses = [];
    let activityRewardAddresses = [];
    let treasuryBalances = [];
    let activityRewardBalances = [];
    for (let i = 0; i < vaultAddress.length; i++) {
      const vault = await sdkA.getVaultInstance(vaultAddress[i]);
      const custodian = await vault.CUSTODIAN();
      await __mockMint(custodian, BigNumber.from('1000000000'), vault, walletSignerA as Signer);

      const usdc = await sdkA.getAssetInstance(vaultAddress[i]);
      const id = vaults.data.find((vault: any) => vault.address === vaultAddress[i]).id;
      const entities = await getVaultEntities(String(id));

      const treasuryAddress = entities.data.find((entity: any) => entity.type === 'treasury').address;
      const activityRewardAddress = entities.data.find((entity: any) => entity.type === 'activity_reward').address;

      treasuryAddresses.push(treasuryAddress);
      activityRewardAddresses.push(activityRewardAddress);

      treasuryBalances.push(await usdc.balanceOf(treasuryAddress));
      activityRewardBalances.push(await usdc.balanceOf(activityRewardAddress));

      console.log(treasuryBalances[i].toString(), activityRewardBalances[i].toString());
    }

    await distributeFixedYieldVault();

    for (let i = 0; i < vaultAddress.length; i++) {
      const usdc = await sdkA.getAssetInstance(vaultAddress[i]);
      const treasuryBalanceAfterDistribution = await usdc.balanceOf(treasuryAddresses[i]);
      const activityRewardBalanceAfterDistribution = await usdc.balanceOf(activityRewardAddresses[i]);

      console.log(treasuryBalanceAfterDistribution.toString(), activityRewardBalanceAfterDistribution.toString());

      expect(treasuryBalanceAfterDistribution.toString()).toEqual(
        treasuryBalances[i].add(BigNumber.from('640000000').mul(2)).toString(),
      );
      expect(activityRewardBalanceAfterDistribution.toString()).toEqual(
        activityRewardBalances[i].add(BigNumber.from('160000000').mul(2)).toString(),
      );
    }
  });
});
