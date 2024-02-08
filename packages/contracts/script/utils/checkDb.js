require('dotenv').config();

const fs = require('fs');
const path = require('path');
const { createClient } = require('@supabase/supabase-js');

const client = createClient(process.env.NEXT_PUBLIC_SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);
const outputFileName = path.resolve(__dirname, '../output/dbdata.json');

async function checkDb() {
  const { data, error } = await client.from('contracts_addresses').select();

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
    await checkDb();
  } catch (e) {
    console.log(e);
  } finally {
    console.log(`Finished checking Database`);
  }
})();
