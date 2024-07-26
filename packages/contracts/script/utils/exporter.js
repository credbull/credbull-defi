const path = require('path');
const fs = require('fs');
const { createClient } = require('@supabase/supabase-js');

const { loadConfiguration } = require('./config');

async function exportAddress(config, chainId) {
  const client = createClient(config.services.supabase.url, config.env.SUPABASE_SERVICE_ROLE_KEY);
  await clearExistingData(client);

  const contracts = {};

  const folderPath = path.resolve(__dirname, '../../broadcast');
  const outputPath = path.resolve(__dirname, '../../deployments/');
  const outputFileName = path.resolve(__dirname, '../../deployments/index.json');

  const deployFiles = await fs.promises.readdir(folderPath);
  for (const deployFile of deployFiles) {
    const deployFilePath = path.resolve(folderPath, deployFile);

    contracts[chainId] = contracts[chainId] || {};
    const runBuffer = fs.readFileSync(path.resolve(deployFilePath, chainId, 'run-latest.json'));

    const output = JSON.parse(runBuffer.toString('utf-8'));
    const transactions = output['transactions'];
    for (const tx of transactions) {
      if (tx['transactionType'] === 'CREATE') {
        const contractName = tx['contractName'];

        contracts[chainId][contractName] = (contracts[chainId][contractName] || []).concat({
          name: contractName,
          address: tx['contractAddress'],
          arguments: tx['arguments'],
        });
      }
    }

    if (!fs.existsSync(outputPath)) {
      fs.mkdirSync(outputPath, { recursive: true });
    }

    fs.writeFileSync(path.resolve(outputFileName), JSON.stringify(contracts));

    let dataToStoreOnDB = [];
    for (let localChainId in contracts) {
      for (let localContracts in contracts[localChainId]) {
        console.log(`Exporting ${localContracts} on chain ${localChainId}`);
        const data = {
          chain_id: localChainId,
          contract_name: localContracts,
          address: contracts[localChainId][localContracts][0].address,
          outdated: false,
        };

        dataToStoreOnDB.push(data);
      }
    }
    if (config.deployment.update_contract_addresses === true) {
      await exportToSupabase(client, dataToStoreOnDB);
    }
  }
  return contracts;
}

async function exportToSupabase(client, dataToStoreOnDB) {
  const wasExported = await client
    .from('contracts_addresses')
    .upsert(dataToStoreOnDB, { onConflict: 'contract_name' })
    .is('outdated', true)
    .select();

  if (wasExported.error || !wasExported.data) {
    console.log(wasExported.error);
    throw wasExported.error;
  }
}

// Function to clear the existing data in the DB before exporting the new data
async function clearExistingData(client) {
  console.log("Clearing 'contract_addresses' table.");
  const contractAddresses = await client.from('contracts_addresses').delete().neq('id', 0);

  if (contractAddresses.error) {
    console.log(`Error in clearing 'contract_addresses' table ${contractAddresses.error}`);
    throw contractAddresses.error;
  }

  console.log("Clearing 'vaults' table.");
  const vaults = await client.from('vaults').delete().neq('id', 0);

  if (vaults.error) {
    console.log(`Error in clearning 'vaults' table ${vaults.error}`);
    throw vaults.error;
  }

  console.log('Database tables cleared successfully!');
}

(async () => {
  try {
    const chainId = Number(process.argv[2]);
    if (isNaN(chainId)) throw new Error(`The specified Chain Id, '${process.argv[2]}', is invalid.`);
    await exportAddress(loadConfiguration(), chainId.toString());
  } catch (e) {
    console.log(e);
  } finally {
    console.log(`Finished exporting contracts`);
  }
})();
