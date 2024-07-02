import { SimpleToken__factory, SimpleUSDC__factory } from '@credbull/contracts';
import { parseUnits } from 'ethers/lib/utils';

import { whitelist } from './utils/admin';
import { loadConfiguration } from './utils/config';
import { balanceLoggerFactory, describeFYWUVault, describeToken, displayValueFor } from './utils/display';
import { Schema } from './utils/schema';
import { userFor } from './utils/user';

export async function depositWithUpside(config: any): Promise<void> {
  Schema.CONFIG_API_URL.parse(config);
  Schema.CONFIG_USER_ADMIN.parse(config);
  Schema.CONFIG_USER_BOB.parse(config);

  console.log('='.repeat(80));
  const toDeposit = 1_000;
  console.log(' Bob plans to deposit USD', toDeposit);

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

  const { data: vaults } = await userBob.sdk.getAllVaults();
  console.log(' Bob queries for all available vaults.');

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
    async (address) => displayShare(await vault.balanceOf(address)),
    async (address) => displayAsset(await asset.balanceOf(address)),
    [
      ['The Vault', vaultData.address],
      ['Bob', userBob.address],
      ['The Custodian', await vault.CUSTODIAN()],
    ],
    async (address) => displayToken(await token.balanceOf(address)),
  );
  await logBalances();

  const depositAmount = parseUnits(toDeposit.toString(), await asset.decimals());
  console.log(' Bob decides to mint his deposit amount of the Asset=', displayAsset(depositAmount));

  const mockUsdc = SimpleUSDC__factory.connect(asset.address, userBob.signer);
  const mintAssetTx = await mockUsdc.mint(userBob.address, depositAmount);
  await mintAssetTx.wait();
  await logBalances();

  const assetSwapApproveTx = await asset.approve(vaultData.address, depositAmount);
  await assetSwapApproveTx.wait();
  console.log(" Bob gives the approval to the vault to swap it's Asset.");

  const tokenAmount = parseUnits(toDeposit.toString(), await token.decimals());
  console.log(' Bob decides to mint his deposit amount of Token=', displayToken(tokenAmount));

  const mockToken = SimpleToken__factory.connect(token.address, userBob.signer);
  const mintTokenTx = await mockToken.mint(userBob.address, tokenAmount);
  await mintTokenTx.wait();
  await logBalances();

  const tokenSwapApproveTx = await token.approve(vaultData.address, tokenAmount);
  await tokenSwapApproveTx.wait();
  console.log(' Bob gives the approval to the vault to swap it`s Token.');

  await userBob.sdk.deposit(vaultData.address, depositAmount, userBob.address);
  console.log(' Bob deposits his Assets to the Vault.');

  await logBalances();
  console.log('='.repeat(80));
}

export async function main() {
  await depositWithUpside(loadConfiguration());
}
