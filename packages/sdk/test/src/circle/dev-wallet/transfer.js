// Import & Initialize

/* eslint-disable @typescript-eslint/no-var-requires */
const { initiateDeveloperControlledWalletsClient } = require('@circle-fin/developer-controlled-wallets');
require('dotenv').config({ path: '../.env' }); // Adjust the path based on your folder structure
/* eslint-enable @typescript-eslint/no-var-requires */

const entitySecret = process.env.CIRCLE_WEB3_ENTITY_SECRET;
const apiKey = process.env.CIRCLE_WEB3_API_KEY;
const walletEthSepolia1Id = process.env.CIRCLE_WEB3_WALLET_ETH_SEPOLIA_1_ID;
const walletEthSepolia2Addr = process.env.CIRCLE_WEB3_WALLET_ETH_SEPOLIA_2_ADDR;

const transferToAddress = process.env.CREDBULL_DEVOPS_DEPLOYER_ADDR;

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
  const usdcId = '5797fbd6-3795-519d-84ca-ec4c5f80c3b1'; // ETH-SEPOLIA USDC
  const ethId = '979869da-9115-5f7d-917d-12d434e56ae7'; // ETH-SEPOLIA ETH

  const amountStr = '1.5';

  try {
    if (1 === 1) {
      console.log(`Starting Token transfer of ${amountStr}`);

      // const transferUsdcResponse = await transferToken(walletEthSepolia1Id, usdcId, walletEthSepolia2Addr, amountStr);
      const transferUsdcResponse = await transferToken(walletEthSepolia1Id, usdcId, transferToAddress, amountStr);
      console.log(`Success !!!`);
      console.log(transferUsdcResponse);
    }
  } catch (error) {
    console.error('Error transferring tokens: ', error);
  }
})();
