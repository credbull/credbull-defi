// Import & Initialize

/* eslint-disable @typescript-eslint/no-var-requires */
const { initiateDeveloperControlledWalletsClient } = require('@circle-fin/developer-controlled-wallets');
require('dotenv').config({ path: '../.env' }); // Adjust the path based on your folder structure
/* eslint-enable @typescript-eslint/no-var-requires */

const entitySecret = process.env.CIRCLE_WEB3_ENTITY_SECRET;
const apiKey = process.env.CIRCLE_WEB3_API_KEY;
const walletSetId = process.env.CIRCLE_WEB3_WALLET_SET_ID;

async function createWallets() {
  const client = initiateDeveloperControlledWalletsClient({
    apiKey: apiKey,
    entitySecret: entitySecret,
  });

  const response = await client.createWallets({
    blockchains: ['ETH-SEPOLIA', 'MATIC-AMOY', 'AVAX-FUJI'],
    count: 2,
    walletSetId: walletSetId,
  });

  return response;
}

(async () => {
  try {
    const walletsResponse = await createWallets();
    console.log(walletsResponse);
  } catch (error) {
    console.error('Error creating wallets:', error);
  }
})();
