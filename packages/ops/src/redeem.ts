import { MockStablecoin__factory } from '@credbull/contracts';
import { formatEther, parseUnits } from 'ethers/lib/utils';

import { loadConfiguration } from './utils/config';
import { describeToken, describeVault, displayValueFor } from './utils/display';
import { Schema } from './utils/schema';
import { userFor } from './utils/user';

export async function redeem(config: any): Promise<void> {
  Schema.CONFIG_API_URL.parse(config);
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

  const toRedeem = parseUnits('1000', 'mwei');
  console.log(' Bob determines an amount of Shares to redeem=', formatEther(toRedeem));

  const { data: vaults } = await userBob.sdk.getAllVaults();
  console.log(' Bob queries for all available vaults=', vaults);

  const vaultData = vaults[0];
  const vault = await userBob.sdk.getVaultInstance(vaultData.address);
  const displayShares = displayValueFor(await vault.decimals());
  console.log(' Bob selects the first vault=', await describeVault(vault));

  const usdc = await userBob.sdk.getAssetInstance(vaultData.address);
  const displayUsdc = displayValueFor(await usdc.decimals());
  console.log(' Bob gets the Asset of the chosen Vault, USDC=', await describeToken(usdc));

  console.log(` The Custodian's USDC balance is=`, displayUsdc(await usdc.balanceOf(await vault.CUSTODIAN())));

  const mockUsdc = MockStablecoin__factory.connect(usdc.address, userBob.signer);
  const mintTx = await mockUsdc.mint(vault.address, toRedeem);
  await mintTx.wait();
  console.log(' Bob mints some USDC, using `MockStableCoin`, to the Vault. Minted=', displayUsdc(toRedeem));

  console.log(" Bob's USDC balance is=", displayUsdc(await usdc.balanceOf(userBob.address)));
  console.log(` The Custodian's USDC balance is=`, displayUsdc(await usdc.balanceOf(await vault.CUSTODIAN())));

  const shares = await vault.balanceOf(userBob.address);
  console.log(" Bob's gets his balance of Shares in the Vault= ", displayShares(shares));

  const approveTx = await vault.approve(vault.address, shares);
  await approveTx.wait();
  console.log(" The Vault approves the spending of Bob's amount of shares.");

  const userAdmin = await userFor(
    config,
    config.users.admin.email_address,
    config.secret.ADMIN_PASSWORD,
    config.secret.ADMIN_PRIVATE_KEY,
  );
  const adminVault = vault.connect(userAdmin.signer);
  const windowCheckTx = await adminVault.toggleWindowCheck(false);
  await windowCheckTx.wait();
  const maturityCheckTx = await adminVault.toggleMaturityCheck(false);
  await maturityCheckTx.wait();
  console.log(' Admin disables the Vault Maturity and Window Checks');

  await userBob.sdk.redeem(vault.address, toRedeem, userBob.address);
  console.log(' Bob redeems his shares from the vault.');

  const balanceOfShares = await vault.balanceOf(userBob.address);
  const balanceOfUsdc = await usdc.balanceOf(userBob.address);

  console.log(` Bob has ${displayShares(balanceOfShares)} ${await vault.symbol()}.`);
  console.log(` Bob has ${displayUsdc(balanceOfUsdc)} USDC.`);
  console.log('='.repeat(80));
}

export async function main() {
  await redeem(loadConfiguration());
}
