import { CredbullFixedYieldVault__factory, MockStablecoin__factory } from '@credbull/contracts';
import { parseUnits } from 'ethers/lib/utils';

import { whitelist } from './utils/admin';
import { loadConfiguration } from './utils/config';
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

  const amount = parseUnits('1000', 'mwei');
  console.log(' Bob determines a value to play with=', amount);

  const { data: vaults } = await userBob.sdk.getAllVaults();
  console.log(' Bob queries for all available vaults=', vaults);

  const vaultData = vaults[0];
  const vault = await userBob.sdk.getVaultInstance(vaultData.address);
  console.log(' Bob selects the first vault.');

  const usdc = await userBob.sdk.getAssetInstance(vaultData.address);
  console.log(' Bob gets the Asset of the chosen Vault, USDC!');

  const mockUsdc = MockStablecoin__factory.connect(usdc.address, userBob.signer);
  const mintTx = await mockUsdc.mint(userBob.address, amount);
  await mintTx.wait();
  console.log(' Bob mints some USDC, using `MockStableCoin`.');

  const approveTx = await usdc.approve(vaultData.address, amount);
  await approveTx.wait();
  console.log(" Bob approves transfers of the Vault's USDC.");

  const connectedTo = CredbullFixedYieldVault__factory.connect(vaultData.address, userBob.signer);
  const toggleTx = await connectedTo.connect(userAdmin.signer).toggleWindowCheck(false);
  await toggleTx.wait();
  console.log(' Admin disables the Vault Maturity Checks?');

  await userBob.sdk.deposit(vaultData.address, amount, userBob.address);
  console.log(' Bob deposits his USDC to the Vault.');

  const balanceOf = await vault.balanceOf(userBob.address);
  console.log(` Bob has ${balanceOf.div(10 ** 6)} USDC deposited in the vault.`);
  console.log('='.repeat(80));
}

export async function main() {
  await deposit(loadConfiguration());
}
