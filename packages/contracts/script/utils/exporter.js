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
    if (['custodian', 'kyc_provider'].includes(e.type)) return [];

    const vault = { order: 0, percentage: 0.2 };
    const treasury = { order: 1, percentage: 0.8 };
    const activity_reward = { order: 2, percentage: 1 };
    const config = { treasury, activity_reward, vault }[e.type];

    return [{ entity_id: e.id, ...config }];
  };

  return client.from('vault_distribution_configs').insert(entities.data.flatMap(makeConfig)).select();
}

async function exportEntitiesToSupabase(client, onChainEntities, vaults) {
  const makeEntities = (v) => {
    return [
      { vault_id: v.id, address: onChainEntities.custodian, type: 'custodian' },
      { vault_id: v.id, address: onChainEntities.kycProvider, type: 'kyc_provider' },
      { vault_id: v.id, address: onChainEntities.treasury, type: 'treasury' },
      { vault_id: v.id, address: onChainEntities.activityReward, type: 'activity_reward' },
      { vault_id: v.id, address: v.address, type: 'vault' },
    ];
  };

  return client.from('vault_distribution_entities').insert(vaults.data.flatMap(makeEntities)).select();
}

async function exportVaultsToSupabase(client, onChainVaults) {
  const vaultAddresses = onChainVaults.map((v) => v.address);
  await client.from('vaults').delete().in('address', vaultAddresses);

  const makeVault = (v) => {
    const opened_at = new Date();
    opened_at.setTime(v.opened_at * 1000);

    const closed_at = new Date();
    closed_at.setTime(v.closed_at * 1000);

    return {
      type: 'fixed_yield',
      status: 'ready',
      opened_at,
      closed_at,
      address: v.address,
      strategy_address: v.address,
      asset_address: v.asset_address,
    };
  };

  return client.from('vaults').insert(onChainVaults.map(makeVault)).select();
}

async function exportToSupabase(onChainEntities, onChainVaults) {
  const client = createClient(process.env.NEXT_PUBLIC_SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

  if(onChainVaults) {
    const vaults = await exportVaultsToSupabase(client, onChainVaults);
    if (vaults.error || !vaults.data) {
      console.log(vaults.error);
      throw vaults.error;
    }
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
  try {
    const contracts = await exportAddress();

    // if (process.env.EXPORT_TO_SUPABASE) {
    //   const chain = process.env.NEXT_PUBLIC_TARGET_NETWORK_ID;
    //   // const vaults = contracts[chain].CredbullVault.map((v) => {
    //   //   return {
    //   //     address: v.address,
    //   //     asset_address: v.arguments[1],
    //   //     opened_at: v.arguments[2],
    //   //     closed_at: v.arguments[3],
    //   //   };
    //   // });
    //   const configDeployment = contracts[chain].CredbullEntities[0].arguments;
    //   const entities = {
    //     custodian: configDeployment[0],
    //     kycProvider: configDeployment[1],
    //     treasury: configDeployment[2],
    //     activityReward: configDeployment[3],
    //   };

    //   await exportToSupabase(entities, null);
    // }
  } catch (e) {
    console.log(e);
  } finally {
    console.log(`Finished exporting contracts`);
  }
})();
