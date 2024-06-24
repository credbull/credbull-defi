import { MockStablecoin__factory } from '@credbull/contracts';
import { BigNumber } from 'ethers';

import { whitelist } from './utils/admin';
import { loadConfiguration } from './utils/config';
import { describeToken, describeVault, displayValueFor } from './utils/display';
import { Schema } from './utils/schema';
import { userFor } from './utils/user';

export async function deposit(config: any) {
  Schema.CONFIG_API_URL.parse(config);
  Schema.CONFIG_USER_ADMIN.parse(config);
  Schema.CONFIG_USER_BOB.parse(config);

  console.log('='.repeat(80));
  const userBob = await userFor(
    config,
    config.users.bob.email_address,
    config.secret.BOB_PASSWORD,
    config.secret.BOB_PRIVATE_KEY,
  );
  await userBob.sdk.linkWallet();
  console.log(' Bob signs a message and links his wallet.');

  const userAdmin = await userFor(
    config,
    config.users.admin.email_address,
    config.secret.ADMIN_PASSWORD,
    config.secret.ADMIN_PRIVATE_KEY,
  );
  await whitelist(config, userAdmin, userBob.address, userBob.id);
  console.log(' Admin whitelists Bob.');

  const toDeposit = 1_000;
  console.log(' Bob plans to deposit USD', toDeposit);

  const { data: vaults } = await userBob.sdk.getAllVaults();
  console.log(' Bob queries for all available vaults.');

  const vaultData = vaults[0];
  const vault = await userBob.sdk.getVaultInstance(vaultData.address);
  console.log(' Bob selects the first vault=', await describeVault(vault));

  const usdc = await userBob.sdk.getAssetInstance(vaultData.address);
  const displayUsdc = displayValueFor(await usdc.decimals());
  console.log(' Bob gets the Asset of the chosen Vault, USDC=', await describeToken(usdc));

  const depositAmount = BigNumber.from(toDeposit).mul(10 ** (await usdc.decimals()));
  const mockUsdc = MockStablecoin__factory.connect(usdc.address, userBob.signer);
  const mintTx = await mockUsdc.mint(userBob.address, depositAmount);
  await mintTx.wait();
  console.log(' Bob buys (mints) his deposit amount of USDC=', displayUsdc(depositAmount));
  console.log(" Bob's USDC balance is=", displayUsdc(await usdc.balanceOf(userBob.address)));
  console.log(` The Custodian's USDC balance is=`, displayUsdc(await usdc.balanceOf(await vault.CUSTODIAN())));

  const approveTx = await usdc.approve(vaultData.address, depositAmount);
  await approveTx.wait();
  console.log(" Bob approves transfers of the Vault's USDC.");

  const toggleTx = await vault.connect(userAdmin.signer).toggleWindowCheck(false);
  await toggleTx.wait();
  console.log(' Admin disables the Vault Window Check');

  await userBob.sdk.deposit(vaultData.address, depositAmount, userBob.address);
  console.log(' Bob deposits his USDC to the Vault.');

  const shareBalance = await vault.balanceOf(userBob.address);
  const displayShares = displayValueFor(await vault.decimals());

  console.log(" Bob's Share balance is=", displayShares(shareBalance));
  console.log(" Bob's USDC balance is=", displayUsdc(await usdc.balanceOf(userBob.address)));
  console.log(` The Custodian's USDC balance is=`, displayUsdc(await usdc.balanceOf(await vault.CUSTODIAN())));
  console.log('='.repeat(80));
}

export async function main() {
  await deposit(loadConfiguration());
}
