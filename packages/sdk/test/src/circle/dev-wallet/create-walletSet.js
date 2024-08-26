// Import & Initialize

/* eslint-disable @typescript-eslint/no-var-requires */
const { initiateDeveloperControlledWalletsClient } = require('@circle-fin/developer-controlled-wallets');
require('dotenv').config({ path: '../.env' }); // Adjust the path based on your folder structure
/* eslint-enable @typescript-eslint/no-var-requires */

const entitySecret = process.env.CIRCLE_WEB3_ENTITY_SECRET;
const apiKey = process.env.CIRCLE_WEB3_API_KEY;
const walletSetName = process.env.CIRCLE_WEB3_WALLET_SET_NAME;

async function createWalletSet() {
  const client = initiateDeveloperControlledWalletsClient({
    apiKey: apiKey,
    entitySecret: entitySecret,
  });

  const response = await client.createWalletSet({
    name: walletSetName,
  });

  return response;
}

(async () => {
  try {
    const walletSetResponse = await createWalletSet();
    console.log(walletSetResponse);
  } catch (error) {
    console.error('Error creating wallet set:', error);
  }
})();
