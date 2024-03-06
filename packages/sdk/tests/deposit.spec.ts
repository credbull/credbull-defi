import { expect, test } from '@playwright/test';
import { config } from 'dotenv';
import { BigNumber, Signer } from 'ethers';

import { CredbullSDK } from '../index';
import { signer } from '../mock/utils/helpers';

import { __mockMint, login, toggleMaturityCheck, toggleWindowCheck } from './utils/admin-ops';

config();

let walletSigner: Signer | undefined = undefined;
let sdk: CredbullSDK;

test.beforeAll(async () => {
  const { access_token } = await login(process.env.USER_A_EMAIL || '', process.env.USER_A_PASSWORD || '');
  walletSigner = signer(process.env.USER_A_PRIVATE_KEY || '0x');
  sdk = new CredbullSDK(access_token, walletSigner as Signer);

  //link wallet
  await sdk.linkWallet();
});

test.skip('Single user Interaction', async () => {
  test('Deposit and redeem flow', async () => {
    let vaults: any;
    let depoistInfo: any;
    const depositAmount = BigNumber.from('100000000');

    // vaults = await test.step('Get all vaults', async () => {
    //   const vaults = await sdk.getAllVaults();
    //   const totalVaults = vaults.data.length;
    //
    //   expect(totalVaults).toBeGreaterThan(0);
    //   expect(vaults).toBeTruthy();
    //   return vaults;
    // });

    //MINT USDC for user
    await test.step('MINT USDC for user', async () => {
      const vaultAddress = vaults.data[0].address;
      const vault = await sdk.getVaultInstance(vaultAddress);
      await __mockMint(await (walletSigner as Signer).getAddress(), depositAmount, vault, walletSigner as Signer);
    });

    //Get approval for deposit
    await test.step('Get approval for deposit', async () => {
      const vaultAddress = vaults.data[0].address;
      const usdc = await sdk.getAssetInstance(vaultAddress);
      await usdc.approve(vaultAddress, depositAmount);

      const approval = await usdc.allowance(await (walletSigner as Signer).getAddress(), vaultAddress);
      expect(approval.toString()).toEqual(depositAmount.toString());
    });

    //Deposit through SDK
    await test.step('Deposit through SDK', async () => {
      const vaultAddress = vaults.data[0].address;

      const user = await (walletSigner as Signer).getAddress();

      const vault = await sdk.getVaultInstance(vaultAddress);
      const shareBalanceBeforeDeposit = await vault.balanceOf(user);
      await sdk.deposit(vaultAddress, depositAmount, user);

      const shareBalanceAfterDeposit = await vault.balanceOf(user);
      expect(shareBalanceBeforeDeposit.add(depositAmount).toString()).toEqual(shareBalanceAfterDeposit.toString());
    });

    //Redeem through SDK
    await test.step('Redeem through SDK', async () => {
      const vaultAddress = vaults.data[0].address;
      const user = await (walletSigner as Signer).getAddress();
      const vault = await sdk.getVaultInstance(vaultAddress);
      //Skip checks
      await toggleMaturityCheck(vault, false);
      await toggleWindowCheck(vault, false);

      const shares = depositAmount;
      const shareBalanceBeforeRedeem = await vault.balanceOf(user);
      await sdk.redeem(vaultAddress, BigNumber.from(shares), user);

      const shareBalanceAfterRedeem = await vault.balanceOf(user);
      expect(shareBalanceBeforeRedeem.sub(shares).toString()).toEqual(shareBalanceAfterRedeem.toString());
    });
  });
});
