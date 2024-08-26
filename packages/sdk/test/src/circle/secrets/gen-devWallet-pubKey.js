/* eslint-disable @typescript-eslint/no-var-requires */
const { initiateDeveloperControlledWalletsClient } = require('@circle-fin/developer-controlled-wallets');
require('dotenv').config({ path: '../.env' }); // Adjust the path based on your folder structure
/* eslint-enable @typescript-eslint/no-var-requires */

const entitySecret = process.env.CIRCLE_WEB3_ENTITY_SECRET;
const apiKey = process.env.CIRCLE_WEB3_API_KEY;

async function getPublicKey() {
  const client = initiateDeveloperControlledWalletsClient({
    apiKey: apiKey,
    entitySecret: entitySecret,
  });

  try {
    const response = await client.getPublicKey();
    return response.data.publicKey; // Return the public key
  } catch (error) {
    console.error('Error fetching public key:', error);
    throw error; // Re-throw the error to be handled by the caller
  }
}

module.exports = { getPublicKey }; // Ensure this line is present and correct
