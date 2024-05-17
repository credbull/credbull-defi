const fs = require('fs');
const path = require('path');
const { createClient } = require('@supabase/supabase-js');

const { loadConfiguration } = require('./config')

const outputFileName = path.resolve(__dirname, '../output/dbdata.json');

async function checkDb(config) {
  const client = createClient(config.services.supabase.url, config.services.supabase.service_role.api_key);

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
