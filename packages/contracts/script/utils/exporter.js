require('dotenv').config();

const path = require('path');
const fs = require('fs');
const { createClient } = require('@supabase/supabase-js');

async function exportAddress() {
  const contracts = {};

  const folderPath = path.resolve(__dirname, '../../broadcast');
  const outputPath = path.resolve(__dirname, '../../deployments');

  const deployFiles = await fs.promises.readdir(folderPath);
  for (const deployFile of deployFiles) {
    const deployFilePath = path.resolve(folderPath, deployFile);
    const chainFiles = await fs.promises.readdir(deployFilePath);

    for (const chainFile of chainFiles) {
      contracts[chainFile] = contracts[chainFile] || {};
      const runBuffer = fs.readFileSync(path.resolve(deployFilePath, chainFile, 'run-latest.json'));

      const output = JSON.parse(runBuffer.toString('utf-8'));
      const transactions = output['transactions'];
      for (const tx of transactions) {
        if (tx['transactionType'] === 'CREATE') {
          const contractName = tx['contractName'];

          contracts[chainFile][contractName] = (contracts[chainFile][contractName] || []).concat({
            name: contractName,
            address: tx['contractAddress'],
            arguments: tx['arguments'],
          });
        }
      }
      if (!fs.existsSync(outputPath)) {
        fs.mkdirSync(outputPath, { recursive: true });
      }

      fs.writeFileSync(path.resolve(outputPath, `${chainFile}.json`), JSON.stringify(contracts[chainFile]));
    }
  }
  return contracts;
}

async function exportConfigsToSupabase(client, entities) {
  const makeConfig = (e) => {
    if (e.type === 'custodian') return [];

    const treasury = { order: 0, percentage: 0.8 };
    const activityReward = { order: 1, percentage: 1 };
    const config = e.type === 'treasury' ? treasury : activityReward;

    return [{ entity_id: e.id, ...config }];
  };

  return client.from('vault_distribution_configs').insert(entities.data.flatMap(makeConfig)).select();
}

async function exportEntitiesToSupabase(client, onChainEntities, vaults) {
  const makeEntities = (v) => {
    return [
      { vault_id: v.id, address: onChainEntities.custodian, type: 'custodian' },
      { vault_id: v.id, address: onChainEntities.treasury, type: 'treasury' },
      { vault_id: v.id, address: onChainEntities.activityReward, type: 'activity_reward' },
    ];
  };

  return client.from('vault_distribution_entities').insert(vaults.data.flatMap(makeEntities)).select();
}

async function exportVaultsToSupabase(client, onChainVaults) {
  const vaultAddresses = onChainVaults.map((v) => v.address);
  await client.from('vaults').delete().in('address', vaultAddresses);

  const makeVault = (v) => {
    const opened_at = new Date();
    opened_at.setTime(v.openedAt * 1000);

    const closed_at = new Date();
    closed_at.setTime(v.closedAt * 1000);

    return {
      type: 'fixed_yield',
      status: 'ready',
      opened_at,
      closed_at,
      address: v.address,
      strategy_address: v.address,
    };
  };

  return client.from('vaults').insert(onChainVaults.map(makeVault)).select();
}

async function exportToSupabase(onChainEntities, onChainVaults) {
  const client = createClient(process.env.NEXT_PUBLIC_SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

  const vaults = await exportVaultsToSupabase(client, onChainVaults);
  if (vaults.error || !vaults.data) {
    console.log(vaults.error);
    throw vaults.error;
  }

  const entities = await exportEntitiesToSupabase(client, onChainEntities, vaults);
  if (entities.error || !entities.data) {
    console.log(entities.error);
    throw entities.error;
  }

  const configs = await exportConfigsToSupabase(client, entities);
  if (configs.error || !configs.data) {
    throw configs.error;
  }
}

(async () => {
  const contracts = await exportAddress();

  if (process.env.EXPORT_TO_SUPABASE) {
    const chain = process.env.NEXT_PUBLIC_TARGET_NETWORK_ID;
    const vaults = contracts[chain].CredbullVault.map((v) => {
      return {
        address: v.address,
        openedAt: v.arguments[5],
        closedAt: v.arguments[6],
      };
    });
    const configDeployment = contracts[chain].CredbullEntities[0].arguments;
    const entities = {
      custodian: configDeployment[0],
      treasury: configDeployment[1],
      activityReward: configDeployment[2],
    };

    await exportToSupabase(entities, vaults);
  }

  console.log(`Finished exporting contracts`);
})();
