// Import & Initialize

/* eslint-disable @typescript-eslint/no-var-requires */
const { initiateDeveloperControlledWalletsClient } = require('@circle-fin/developer-controlled-wallets');
require('dotenv').config({ path: '../.env' }); // Adjust the path based on your folder structure
/* eslint-enable @typescript-eslint/no-var-requires */

const entitySecret = process.env.CIRCLE_WEB3_ENTITY_SECRET;
const apiKey = process.env.CIRCLE_WEB3_API_KEY;
const walletSetId = process.env.CIRCLE_WEB3_WALLET_SET_ID;

const client = initiateDeveloperControlledWalletsClient({
  apiKey: apiKey,
  entitySecret: entitySecret,
});

async function createWalletSet() {
  const response = await client.createWalletSet({
    name: walletSetName,
  });

  return response;
}

async function createWallets() {
  const response = await client.createWallets({
    blockchains: ['ETH-SEPOLIA'], // Testnets:  ['ETH-SEPOLIA', 'MATIC-AMOY', 'AVAX-FUJI'],
    count: 1, // number of walelts to create
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
