import { MockStablecoin__factory } from '@credbull/contracts';
import { formatUnits, parseUnits } from 'ethers/lib/utils';

import { loadConfiguration } from './utils/config';
import { balanceLoggerFactory, describeFYWUVault, describeToken, displayValueFor } from './utils/display';
import { Schema } from './utils/schema';
import { userFor } from './utils/user';

export async function redeemWithUpside(config: any): Promise<void> {
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

  const { data: vaults } = await userBob.sdk.getAllVaults();
  console.log(' Bob queries for all available vaults=', vaults);

  const vaultData = vaults.find((v: any) => v.type === 'fixed_yield_upside');
  if (vaultData === undefined) throw new Error('No Fixed Yield Vault With Upside found.');
  const vault = await userBob.sdk.getUpsideVaultInstance(vaultData.address);
  const displayShare = displayValueFor(await vault.decimals());
  console.log(' Bob selects the first Fixed Yield Vault With Upside=', await describeFYWUVault(vault));

  const asset = await userBob.sdk.getAssetInstance(vaultData.address);
  const displayAsset = displayValueFor(await asset.decimals());
  console.log(' Bob gets the Asset of the Vault=', await describeToken(asset));

  const token = await userBob.sdk.getTokenInstance(vaultData.address);
  const displayToken = displayValueFor(await token.decimals());
  console.log(' Bob gets the Token of the Vault=', await describeToken(token));

  // A complicated utility logging function for outputting balances for all actors to see state changes.
  const logBalances = balanceLoggerFactory(
    async (address) => await vault.balanceOf(address),
    displayShare,
    async (address) => await asset.balanceOf(address),
    displayAsset,
    [
      ['The Vault', vaultData.address],
      ['Bob', userBob.address],
      ['The Custodian', await vault.CUSTODIAN()],
    ],
    async (address) => await token.balanceOf(address),
    displayToken,
  );
  await logBalances();

  const redeemAmount = await vault.balanceOf(userBob.address);
  console.log(' Bob decides to redeem all his Shares=', formatUnits(redeemAmount, await vault.decimals()));
  if (redeemAmount.lte(0)) throw new Error('No Shares to redeem.');

  const mockUsdc = MockStablecoin__factory.connect(asset.address, userBob.signer);
  const mintAssetTx = await mockUsdc.mint(vaultData.address, redeemAmount);
  await mintAssetTx.wait();
  console.log(' Bob mints the redeem amount of Asset to the Vault=', displayAsset(redeemAmount));
  await logBalances();

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

  await userBob.sdk.redeem(vaultData.address, redeemAmount, userBob.address);
  console.log(' Bob redeems his Shares from the Vault.');
  await logBalances();
  console.log('='.repeat(80));
}

export async function main(): Promise<void> {
  await redeemWithUpside(loadConfiguration());
}
