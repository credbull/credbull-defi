import { createClient } from '@supabase/supabase-js';

import { loadConfiguration } from './config';

async function truncateTables(config: any) {
  const supabaseClient = createClient(config.services.supabase.url, config.env.SUPABASE_SERVICE_ROLE_KEY);

  console.log("Clearing 'contract_addresses' table.");
  const { error: error1 } = await supabaseClient.from('contracts_addresses').delete().neq('id', 0);
  if (error1) throw error1;

  console.log("Clearing 'vaults' table.");
  const { error: error2 } = await supabaseClient.from('vaults').delete().neq('id', 0);
  if (error2) throw error2;
}

async function main() {
  try {
    await truncateTables(loadConfiguration());
  } catch (e) {
    console.log(e);
  }
}

main();
