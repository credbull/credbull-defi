// Import & Initialize

/* eslint-disable @typescript-eslint/no-var-requires */
const { initiateDeveloperControlledWalletsClient } = require('@circle-fin/developer-controlled-wallets');
require('dotenv').config({ path: '../.env' }); // Adjust the path based on your folder structure
/* eslint-enable @typescript-eslint/no-var-requires */

const entitySecret = process.env.CIRCLE_WEB3_ENTITY_SECRET;
const apiKey = process.env.CIRCLE_WEB3_API_KEY;
const walletEthSepolia1Id = process.env.CIRCLE_WEB3_WALLET_ETH_SEPOLIA_1_ID;

const client = initiateDeveloperControlledWalletsClient({
  apiKey: apiKey,
  entitySecret: entitySecret,
});

async function getWalletTokenBalance(walletId) {
  const response = await client.getWalletTokenBalance({ id: walletId });
  const tokenBalances = response.data?.tokenBalances;

  // Check if tokenBalances exists and is an array, then log it
  if (Array.isArray(tokenBalances)) {
    console.log(JSON.stringify(tokenBalances, null, 2)); // Pretty-print the entire tokenBalances array
  } else {
    console.log('No token balances found.');
  }
  return response;
}

(async () => {
  try {
    if (1 === 1) {
      const response = await getWalletTokenBalance(walletEthSepolia1Id);
      console.log(`Success !!!`);
      console.log(response);
    }
  } catch (error) {
    console.error('Error getting wallet balance:', error);
  }
})();
