require('dotenv').config();

const path = require('path');
const fs = require('fs');
const { createClient } = require('@supabase/supabase-js');

async function exportAddress() {
  const contracts = {};

  const folderPath = path.resolve(__dirname, '../../broadcast');
  const outputPath = path.resolve(__dirname, '../../deployments/');
  const outputFileName = path.resolve(__dirname, '../../deployments/index.json');

  const deployFiles = await fs.promises.readdir(folderPath);
  for (const deployFile of deployFiles) {
    const deployFilePath = path.resolve(folderPath, deployFile);
    const chainDir = process.env.NEXT_PUBLIC_TARGET_NETWORK_ID;

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
    if (process.env.EXPORT_TO_SUPABASE === 'true') {
      await exportToSupabase(dataToStoreOnDB);
    }
  }
  return contracts;
}

async function exportToSupabase(dataToStoreOnDB) {
  const check = await fetch('http://127.0.0.1:3001/', { method: 'GET'});
  console.log('simple network check', await check.json());

  const anvilCheck = await fetch('http://api:3001/', { method: 'GET'});
  console.log('api check', await anvilCheck.json());

  const client = createClient(process.env.NEXT_PUBLIC_SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

  const config = await client
    .from('contracts_addresses')
    .upsert(dataToStoreOnDB, { onConflict: 'contract_name' })
    .is('outdated', true)
    .select();

  if (config.error || !config.data) {
    console.log(config.error);
    throw config.error;
  }
}

(async () => {
  try {
    await exportAddress();
  } catch (e) {
    console.log(e);
  } finally {
    console.log(`Finished exporting contracts`);
  }
})();
