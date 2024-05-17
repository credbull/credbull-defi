const path = require('path');
const fs = require('fs');
const { createClient } = require('@supabase/supabase-js');

const { loadConfiguration } = require('./config');

async function exportAddress(config) {
  const client = createClient(config.services.supabase.url, config.services.supabase.service_role.api_key);
  await clearExistingData(client);

  const contracts = {};

  const folderPath = path.resolve(__dirname, '../../broadcast');
  const outputPath = path.resolve(__dirname, '../../deployments/');
  const outputFileName = path.resolve(__dirname, '../../deployments/index.json');

  const chainDir = config.application.network_id.toString();
  const deployFiles = await fs.promises.readdir(folderPath);
  for (const deployFile of deployFiles) {
    const deployFilePath = path.resolve(folderPath, deployFile);

    contracts[chainDir] = contracts[chainDir] || {};
    const runBuffer = fs.readFileSync(path.resolve(deployFilePath, chainDir, 'run-latest.json'));

    const output = JSON.parse(runBuffer.toString('utf-8'));
    const transactions = output['transactions'];
    for (const tx of transactions) {
      if (tx['transactionType'] === 'CREATE') {
        const contractName = tx['contractName'];

        contracts[chainDir][contractName] = (contracts[chainDir][contractName] || []).concat({
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
    for (let chainId in contracts) {
      for (let localContracts in contracts[chainId]) {
        console.log(`Exporting ${localContracts} on chain ${chainId}`);
        const data = {
          chain_id: chainId,
          contract_name: localContracts,
          address: contracts[chainId][localContracts][0].address,
          outdated: false,
        };

        dataToStoreOnDB.push(data);
      }
    }
    if (config.application.export_contracts === true) {
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
    await exportAddress(loadConfiguration());
  } catch (e) {
    console.log(e);
  } finally {
    console.log(`Finished exporting contracts`);
  }
})();
