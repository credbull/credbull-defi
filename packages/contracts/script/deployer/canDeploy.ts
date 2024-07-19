import { createClient } from '@supabase/supabase-js';

import { loadConfiguration } from '../utils/config';

async function canDeploy(config: any, chainId: string, contracts: string[]): Promise<boolean> {
  const supabaseClient = createClient(config.services.supabase.url, config.env.SUPABASE_SERVICE_ROLE_KEY);

  const { data, error } = await supabaseClient
    .from('contracts_addresses')
    .select('contract_name')
    .eq('chain_id', chainId)
    .in('contract_name', contracts)
    .is('outdated', false);
  if (error) throw error;
  const canDeploy = data === undefined || data.length === 0;
  if (!canDeploy) {
    console.log(`  Deployed Contract(s)= '${data.join(', ')}'`);
  }
  return canDeploy;
}

function usage(reason: string) {
  const msg = `
  FAILED: ${reason}
  Usage: ${process.argv0} --chain-id <chain id> --contracts <contract names>
    - <chain id>: The Chain Id number
    - <contract names>: A comma-separated list of Contract Names, e.g. 'Contract1,Contract2'
    NOTE: parameter order is exactly as above`;
  throw new Error(msg);
}

async function main() {
  let exitCode = 1;
  try {
    if (process.argv.length < 6) usage('insufficient parameters provided.');
    const chainId = new Number(process.argv[3]) || usage(`Chain Id '${process.argv[3]}' is not a number.`);
    const contracts = process.argv[5].split(',').map((s) => s.trim());
    console.log(`Checking for contracts '${contracts.join(', ')}' on Chain '${chainId}'.`);
    if (await canDeploy(loadConfiguration(), chainId.toString(), contracts)) {
      exitCode = 0;
    }
  } catch (e) {
    console.log(e);
  } finally {
    process.exit(exitCode);
  }
}

main();
