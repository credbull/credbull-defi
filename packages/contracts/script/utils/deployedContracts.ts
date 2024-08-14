import fs from 'fs';
import path from 'path';
import { createClient } from '@supabase/supabase-js';

import { loadConfiguration } from './config';

const PARAM_CHAIN_ID = '--chain-id';
const PARAM_OUTPUT_FILE = '--output-file';

const DEFAULT_OUTPUT_FILE = path.resolve(__dirname, '../output/deployedContracts');

/**
 * Queries the `contract_addresses` table for all contracts deployed on `chainId` chain, and exports the JSON to the
 * `outputFile`.
 *
 * @param config The loaded configuration.
 * @param chainId The [string] Chain Id to query for.
 * @param outputFile The [string] Output File path.
 */
async function exportDeployedContracts(config: any, chainId: string, outputFile: string) {
  const supabaseClient = createClient(config.services.supabase.url, config.env.SUPABASE_SERVICE_ROLE_KEY);
  const { data, error } = await supabaseClient
    .from('contracts_addresses')
    .select('contract_name, address')
    .eq('chain_id', chainId)
    .is('outdated', false);
  if (error) throw error;

  const toExport = data.reduce((acc, v) => Object.assign(acc, { [v.contract_name]: v.address }), {});
  fs.writeFileSync(outputFile, JSON.stringify(toExport));

  console.log(`  Exported '${data.length}' contracts for Chain '${chainId}' to file ${outputFile}.`);
}

function withSuffix(outputFile: string, chainId: string): string {
  return outputFile + '-' + chainId + '.json';
}

function usage(reason: string) {
  const msg = `
  FAILED: ${reason}
  Usage: ${process.argv0} ${PARAM_CHAIN_ID} <chain id> [${PARAM_OUTPUT_FILE} <file path>]
    - <chain id>: The Chain Id number
    - <file path>: An optional, base output file. It will be suffixed with '-<chain id>.json'.
                   Defaults to: '${DEFAULT_OUTPUT_FILE}-<chain id>.json'
    Result: 0 if the contracts for the '<chain id>' chain are exported to the output file, 1 otherwise.`;
  throw new Error(msg);
}

async function main() {
  // We default to failing by setting 1 as the Exit Code.
  process.exitCode = 1;

  try {
    process.argv.length < 4 && usage('Insufficient parameters provided.');
    process.argv[2] === PARAM_CHAIN_ID || usage(`Parameter 1 is not '${PARAM_CHAIN_ID}'.`);
    const rawChainId = new Number(process.argv[3]) || usage(`Chain Id '${process.argv[3]}' is not a number.`);
    const chainId = rawChainId.toString();

    let outputFile = withSuffix(DEFAULT_OUTPUT_FILE, chainId);
    if (process.argv[4]) {
      process.argv[4] === PARAM_OUTPUT_FILE || usage(`Parameter 3 is not '${PARAM_OUTPUT_FILE}'.`);
      process.argv[5]?.trim() || usage(`Output File '${process.argv[5]}' is invalid.`);

      outputFile = path.resolve(withSuffix(process.argv[5]?.trim(), chainId));
    }
    console.log(`Exporting deployed contracts for Chain '${chainId}' to file '${outputFile}'.`);

    const outputDir = path.dirname(outputFile);
    if (!fs.existsSync(outputDir)) {
      fs.mkdirSync(outputDir, { recursive: true });
      console.log(`  Created the output file directory: ${outputDir}.`);
    }

    await exportDeployedContracts(loadConfiguration(), chainId, outputFile);
    process.exitCode = 0;
  } catch (e) {
    console.log(e);
  }
}

main();
