// Import & Initialize

/* eslint-disable @typescript-eslint/no-var-requires */
const { initiateDeveloperControlledWalletsClient } = require('@circle-fin/developer-controlled-wallets');
require('dotenv').config({ path: '../.env' }); // Adjust the path based on your folder structure
/* eslint-enable @typescript-eslint/no-var-requires */

const entitySecret = process.env.CIRCLE_WEB3_ENTITY_SECRET;
const apiKey = process.env.CIRCLE_WEB3_API_KEY;
const walletEthSepolia1Id = process.env.CIRCLE_WEB3_WALLET_ETH_SEPOLIA_1_ID;
const walletEthSepolia2Addr = process.env.CIRCLE_WEB3_WALLET_ETH_SEPOLIA_2_ADDR;

const client = initiateDeveloperControlledWalletsClient({
  apiKey: apiKey,
  entitySecret: entitySecret,
});

async function transferToken(walletId, tokenId, toAddress, amount) {
  const response = await client.createTransaction({
    walletId: walletId, // '<ID_OF_PREVIOUSLY_GENERATED_WALLET>',
    tokenId: tokenId, // '<ID_OF_THE_TOKEN_YOU_WANT_TO_TRANSFER>',
    destinationAddress: toAddress, // '<ADDRESS_OF_THE_DESTINATION_WALLET>',
    amounts: [amount],
    fee: {
      type: 'level',
      config: {
        feeLevel: 'HIGH',
      },
    },
  });

  return response;
}

(async () => {
  const usdcId = '5797fbd6-3795-519d-84ca-ec4c5f80c3b1';
  const amountStr = '1';

  try {
    // transfer 1 USDC
    if (1 !== 1) {
      const transferUsdcResponse = await transferToken(walletEthSepolia1Id, usdcId, walletEthSepolia2Addr, amountStr);
      console.log(transferUsdcResponse);
    }
  } catch (error) {
    console.error('Error creating wallets:', error);
  }
})();
