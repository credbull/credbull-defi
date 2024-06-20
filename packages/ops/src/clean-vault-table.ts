import { CredbullFixedYieldVault__factory } from '@credbull/contracts';

import { loadConfiguration } from './utils/config';
import { supabaseAdminClient } from './utils/database';
import { signerFor } from './utils/ethers';
import { Schema } from './utils/schema';

/**
 * Pauses all Vault contracts and truncates the Vault database table.
 *
 * @param config The applicable configuration object.
 * @throws PostgrestError if any database operation fails.
 * @throws ZodError if the `config` object does not satisfy all configuration needs.
 */
export async function cleanVaultTable(config: any) {
  Schema.CONFIG_ADMIN_PRIVATE_KEY.parse(config);

  const supabaseAdmin = supabaseAdminClient(config);
  const { data, error } = await supabaseAdmin.from('vaults').select();
  if (error) throw error;
  if (data.length === 0) {
    console.log('No vault data to clean');
    return;
  }

  const adminSigner = signerFor(config, config.secret.ADMIN_PRIVATE_KEY);

  console.log('='.repeat(80));
  console.log(` Pausing ${data.length} Vaults.`);
  for (const vault of data) {
    const contract = CredbullFixedYieldVault__factory.connect(vault.address, adminSigner);
    const tx = await contract.pauseVault();
    await tx.wait();
    console.log(`  Vault ${vault.address} paused.`);
  }
  console.log('-'.repeat(80));

  const { error: deleteError } = await supabaseAdmin.from('vaults').delete().neq('id', 0);
  if (deleteError) throw deleteError;

  console.log(' Vault Table truncated.');
  console.log('='.repeat(80));
}

/**
 * Invoked by the command line processor, pauses all Vault contracts and truncates the Vault database table.
 *
 * @throws ZodError if the loaded configuration does not satisfy all configuration needs.
 */
export async function main() {
  await cleanVaultTable(loadConfiguration());
}

export default main;
