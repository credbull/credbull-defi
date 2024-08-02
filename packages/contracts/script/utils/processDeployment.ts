import path from 'path';
import fs from 'fs';
import { createClient } from '@supabase/supabase-js';

import { loadConfiguration } from './config';

// Encapsulates the create contract transaction details extracted from the `forge` Transaction Log.
type Tx = { name: string; address: string; arguments: string[] };

/**
 * Interrogate all the latest Transaction Logs, per Deployment Script, for the [chainId] Blockchain, extracting the
 * list of Contract Creation transactions.
 *
 * @param chainId The [string] effective Chain Id.
 * @returns The list of Create Transactions from the Transaction Log.
 */
async function extractTransactions(chainId: string): Promise<Tx[]> {
  const broadcastDir = path.resolve(__dirname, '../../broadcast');
  const deployScripts = await fs.promises.readdir(broadcastDir);
  const txLogFiles = deployScripts.map((ds) => path.resolve(broadcastDir, ds, chainId, 'run-latest.json'));
  const txLogs = txLogFiles.map((tlf) => JSON.parse(fs.readFileSync(tlf).toString('utf-8')));
  return txLogs.map((tl) =>
    tl['transactions']
      .filter((tx: any) => tx['transactionType'] === 'CREATE')
      .map((tx: any) => ({
        name: tx['contractName'],
        address: tx['contractAddress'],
        arguments: tx['arguments'],
      })),
  );
}

/**
 * Processes the Create Transactions into a JSON structure and writes it out to the Deployment Report file.
 *
 * @param chainId The [string] effective Chain Id.
 * @param transactions The array of [Tx] that is the Create Transaction details.
 */
async function writeDeploymentsReport(chainId: string, transactions: Tx[]) {
  const deployed = transactions.reduce(
    (acc: any, v: any) => {
      const mapped = v.map((tx: any) => ({ [tx['name']]: (acc[chainId][tx['name']] || []).concat(tx) }));
      const merged = Object.assign({}, ...mapped);
      return { [chainId]: Object.assign(acc[chainId], merged) };
    },
    { [chainId]: {} },
  );
  const outputDir = path.resolve(__dirname, '../../deployments/');
  if (!fs.existsSync(outputDir)) fs.mkdirSync(outputDir, { recursive: true });
  const outputFile = path.resolve(outputDir, 'index.json');
  fs.writeFileSync(path.resolve(outputFile), JSON.stringify(deployed));
  console.log(`  Deployments Report written to: `, outputFile);
}

/**
 * Process the Create Transactions into data rows for the `contract_addresses` table and upserts the data to the
 * database.
 *
 * @param config The configuration object.
 * @param chainId The [string] effective Chain Id.
 * @param transactions The array of [Tx] that is the Create Transaction details.
 */
async function updateDatabase(config: any, chainId: string, transactions: Tx[]) {
  const rows = transactions
    .flat()
    .map((tx: any) => ({ chain_id: chainId, contract_name: tx['name'], address: tx['address'] }));

  const supabaseClient = createClient(config.services.supabase.url, config.env.SUPABASE_SERVICE_ROLE_KEY);
  // TODO (JL,2024-08-02): The `contract_addresses` design is broken for multiple networks. 'outdated' is never used,
  //  the table has a unique index on `contract_name` (meaning only 1 contract deployment per environment), the pk on
  //  `id, chain_id, contract_name` (which is misleading) and the following upsert should not actually work, except
  //  that the table was being cleared per-deployment before now.
  const { error } = await supabaseClient
    .from('contracts_addresses')
    .upsert(rows, { onConflict: 'contract_name' })
    .is('outdated', true)
    .select();
  if (error) throw error;
  console.log("  Database table 'contract_addresses' updated.");
}

/**
 * Post-processes the Transaction Logs for the latest deployment to the `chainId` chain.
 *
 * @param config The configuration object.
 * @param chainId The [string] effective Chain Id.
 */
async function processDeployment(config: any, chainId: string) {
  const transactions = await extractTransactions(chainId);

  writeDeploymentsReport(chainId, transactions);

  // If enabled, update the 'contract_addresses' table with the deployed contracts details.
  if (config.deployment.update_contract_addresses === true) {
    await updateDatabase(config, chainId, transactions);
  }
}

async function main() {
  try {
    const chainId = Number(process.argv[2]);
    if (isNaN(chainId)) throw new Error(`The specified Chain Id, '${process.argv[2]}', is invalid.`);
    await processDeployment(loadConfiguration(), chainId.toString());
  } catch (e) {
    console.log(e);
    process.exitCode = 1;
  } finally {
    console.log(`Post-processing of the deployment: COMPLETE.`);
  }
}

main();
