import { MockStablecoin__factory } from '@credbull/contracts';
import { formatEther, parseUnits } from 'ethers/lib/utils';

import { loadConfiguration } from './utils/config';
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
  const mintTx = await mockUsdc.mint(vault.address, amount);
  await mintTx.wait();
  console.log(' The Vault mints some USDC, using `MockStableCoin`.');

  const shares = await vault.balanceOf(userBob.address);
  console.log(" Bob's gets his balance of Shares in the Vault= ", shares);

  const approveTx = await vault.approve(vault.address, shares);
  await approveTx.wait();
  console.log(" The Vault approves the spending of Bob's amount of shares.");

  await userBob.sdk.redeem(vault.address, shares, userBob.address);
  console.log(' Bob redeems his shares from the vault.');

  const balanceOfInner = await vault.balanceOf(userBob.address);
  const balanceOfUSDC = await usdc.balanceOf(userBob.address);

  console.log(` Bob has ${formatEther(balanceOfInner)} sToken. - OK`);
  console.log(` Bob has ${formatEther(balanceOfUSDC)} USDC. - OK`);
  console.log('='.repeat(80));
}

export async function main() {
  await redeem(loadConfiguration());
}
