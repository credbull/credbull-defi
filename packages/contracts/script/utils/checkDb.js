require('dotenv').config();

const fs = require('fs');
const path = require('path');
const { createClient } = require('@supabase/supabase-js');
const { load } = require('js-toml');

const outputFileName = path.resolve(__dirname, '../output/dbdata.json');

// Loads the environment-specified TOML configuration file.
async function loadConfiguration() {
  const env = process.env.ENVIRONMENT;
  const configFile = path.resolve(__dirname, `../../resource/${env}.toml`);
  console.log(`Loading configuration from: '${configFile}'`);
  const toml = fs.readFileSync(configFile, 'utf8');
  return load(toml);
}

async function checkDb(config) {
  const client = createClient(config.services.supabase.url, config.services.supabase.api_key);

  const { data, error } = await client.from('contracts_addresses').select().is('outdated', false);

  if (error) {
    throw error;
  }

  let dataToExport = {};

  if (data.length > 0) {
    data.map((i) => {
      dataToExport[i.contract_name] = i.address;
    });
  }

  fs.writeFileSync(path.resolve(outputFileName), JSON.stringify(dataToExport));
}

(async () => {
  try {
    await checkDb(loadConfiguration());
  } catch (e) {
    console.log(e);
  } finally {
    console.log(`Finished checking Database`);
  }
})();
