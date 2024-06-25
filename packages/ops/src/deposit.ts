import { MockStablecoin__factory } from '@credbull/contracts';
import { BigNumber } from 'ethers';

import { whitelist } from './utils/admin';
import { loadConfiguration } from './utils/config';
import { balanceLoggerFactory, describeFYVault, describeToken, displayValueFor } from './utils/display';
import { Schema } from './utils/schema';
import { userFor } from './utils/user';

export async function deposit(config: any) {
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

  const vaultData = vaults.find((v: any) => v.type === 'fixed_yield');
  if (vaultData === undefined) throw new Error('No Fixed Yield Vault found.');
  const vault = await userBob.sdk.getVaultInstance(vaultData.address);
  const displayShare = displayValueFor(await vault.decimals());
  console.log(' Bob selects the first vault=', await describeFYVault(vault));

  const asset = await userBob.sdk.getAssetInstance(vaultData.address);
  const displayAsset = displayValueFor(await asset.decimals());
  console.log(' Bob gets the Asset (USDC) of the chosen Vault=', await describeToken(asset));

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
  );
  await logBalances();

  const depositAmount = BigNumber.from(toDeposit).mul(10 ** (await asset.decimals()));
  const mockUsdc = MockStablecoin__factory.connect(asset.address, userBob.signer);
  const mintTx = await mockUsdc.mint(userBob.address, depositAmount);
  await mintTx.wait();
  console.log(' Bob buys (mints) his deposit amount of USDC=', displayAsset(depositAmount));
  await logBalances();

  const approveTx = await asset.approve(vaultData.address, depositAmount);
  await approveTx.wait();
  console.log(" Bob approves transfers of the Vault's USDC.");

  const toggleTx = await vault.connect(userAdmin.signer).toggleWindowCheck(false);
  await toggleTx.wait();
  console.log(' Admin disables the Vault Window Check');

  await userBob.sdk.deposit(vaultData.address, depositAmount, userBob.address);
  console.log(' Bob deposits his USDC to the Vault.');

  await logBalances();
  console.log('='.repeat(80));
}

export async function main() {
  await deposit(loadConfiguration());
}
