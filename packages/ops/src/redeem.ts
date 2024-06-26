import { MockStablecoin__factory } from '@credbull/contracts';
import { formatUnits } from 'ethers/lib/utils';

import { loadConfiguration } from './utils/config';
import { balanceLoggerFactory, describeFYVault, describeToken, displayValueFor } from './utils/display';
import { Schema } from './utils/schema';
import { userFor } from './utils/user';

export async function redeem(config: any): Promise<void> {
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

  const vaultData = vaults.find((v: any) => v.type === 'fixed_yield');
  if (vaultData === undefined) throw new Error('No Fixed Yield Vault found.');
  const vault = await userBob.sdk.getVaultInstance(vaultData.address);
  const displayShare = displayValueFor(await vault.decimals());
  console.log(' Bob selects the first vault=', await describeFYVault(vault));

  const redeemAmount = await vault.balanceOf(userBob.address);
  console.log(' Bob decides to redeem all his Shares=', formatUnits(redeemAmount, await vault.decimals()));
  if (redeemAmount.lte(0)) throw new Error('No Shares to redeem.');

  const asset = await userBob.sdk.getAssetInstance(vaultData.address);
  const displayAsset = displayValueFor(await asset.decimals());
  console.log(' Bob gets the Asset of the chosen Vault, USDC=', await describeToken(asset));

  // A complicated utility logging function for outputting balances for all actors to see state changes.
  const logBalances = balanceLoggerFactory(
    async (address) => displayShare(await vault.balanceOf(address)),
    async (address) => displayAsset(await asset.balanceOf(address)),
    [
      ['The Vault', vaultData.address],
      ['Bob', userBob.address],
      ['The Custodian', await vault.CUSTODIAN()],
    ],
  );
  await logBalances();

  const mockUsdc = MockStablecoin__factory.connect(asset.address, userBob.signer);
  const mintTx = await mockUsdc.mint(vault.address, redeemAmount);
  await mintTx.wait();
  console.log(' Bob mints some USDC, using `MockStableCoin`, to the Vault. Minted=', displayAsset(redeemAmount));
  await logBalances();

  const approveTx = await vault.approve(vault.address, redeemAmount);
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

  await userBob.sdk.redeem(vault.address, redeemAmount, userBob.address);
  console.log(' Bob redeems his shares from the vault.');
  await logBalances();
  console.log('='.repeat(80));
}

export async function main() {
  await redeem(loadConfiguration());
}
