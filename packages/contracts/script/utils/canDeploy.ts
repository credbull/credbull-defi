import { createClient } from '@supabase/supabase-js';

import { loadConfiguration } from './config';

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
  Usage: ${process.argv0} --chain-id <chain id> --deploy-units <deploy unit names>
    - <chain id>: The Chain Id number
    - <deploy unit names>: A comma-separated list of the deployment unit names ('vaults', 'vaults_support' and 'cbl').
    NOTE: Only parameter order exactly as above is supported.
    Result: 0 if none of the contracts of the deployment unit(s) are deployed on <chain id> network. 1 otherwise.`;
  throw new Error(msg);
}

type DeploymentUnit = 'vaults' | 'vaults_support' | 'cbl';

async function main() {
  // We default to failing by setting 1 as the Exit Code.
  process.exitCode = 1;

  try {
    if (process.argv.length < 6) usage('Insufficient parameters provided.');
    process.argv[2] === '--chain-id' || usage("Parameter 1 is not '--chain-id'.");
    const chainId = new Number(process.argv[3]) || usage(`Chain Id '${process.argv[3]}' is not a number.`);
    process.argv[4] === '--deploy-units' || usage("Parameter 3 is not '--deploy-units'.");
    process.argv[5]?.trim() || usage(`Deployment Units '${process.argv[5]}' is empty.`);

    const config = loadConfiguration();
    const contracts = process.argv[5]
      .split(',')
      .map((du) => du.trim() as DeploymentUnit)
      .flatMap((du: DeploymentUnit) => config.deployment[du].contracts);

    console.log('Contracts=', contracts);

    console.log(`Checking for contracts '${contracts.join(', ')}' on Chain '${chainId}'.`);
    const noneDeployed = !(await isAnyDeployed(config, chainId.toString(), contracts));
    if (noneDeployed) {
      console.log(`None of '${contracts.join(', ')}' are deployed on Chain '${chainId}'.`);
      process.exitCode = 0;
    }
  } catch (e) {
    console.log(e);
  }
}

main();
