import { createClient } from '@supabase/supabase-js';

import { loadConfiguration } from '../utils/config';

async function isAnyDeployed(config: any, chainId: string, contracts: string[]): Promise<boolean> {
  const supabaseClient = createClient(config.services.supabase.url, config.env.SUPABASE_SERVICE_ROLE_KEY);

  const { data, error } = await supabaseClient
    .from('contracts_addresses')
    .select('contract_name')
    .eq('chain_id', chainId)
    .in('contract_name', contracts)
    .is('outdated', false);
  if (error) throw error;
  const someDeployed = data?.length > 0;
  if (someDeployed) {
    console.log(`  Deployed Contract(s)= '${data.map((d) => d.contract_name).join(', ')}'`);
  }
  return someDeployed;
}

function usage(reason: string) {
  const msg = `
  FAILED: ${reason}
  Usage: ${process.argv0} --chain-id <chain id> --contracts <contract names>
    - <chain id>: The Chain Id number
    - <contract names>: A comma-separated list of Contract Names, e.g. 'Contract1,Contract2'
    NOTE: parameter order is exactly as above
    Result: 0 if none of <contract names> are deployed on <chain id> network. 1 otherwise.`;
  throw new Error(msg);
}

async function main() {
  process.exitCode = 1;
  try {
    if (process.argv.length < 6) usage('Insufficient parameters provided.');
    const chainId = new Number(process.argv[3]) || usage(`Chain Id '${process.argv[3]}' is not a number.`);
    const contracts = process.argv[5].split(',').map((s) => s.trim());
    console.log(`Checking for contracts '${contracts.join(', ')}' on Chain '${chainId}'.`);
    const noneDeployed = !(await isAnyDeployed(loadConfiguration(), chainId.toString(), contracts));
    if (noneDeployed) {
      console.log(`None of '${contracts.join(', ')}' are deployed on Chain '${chainId}'.`);
      process.exitCode = 0;
    }
  } catch (e) {
    console.log(e);
  }
}

main();
