// Import & Initialize

/* eslint-disable @typescript-eslint/no-var-requires */
const web3 = require('web3');
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

async function depositForBurn(walletId, amountWithDecimals) {
  const circleDomain = '7'; // Arbitrum = 3, PolygonPoS=7 https://developers.circle.com/stablecoins/docs/supported-domains
  const encodedDestinationAddress = web3.eth.abi.encodeParameter('address', walletEthSepolia2Addr);

  console.log('********* encodedDestAddress', encodedDestinationAddress);

  // The abiParameters property defines the values to pass to the function. For the call to depositForBurn, they are amount, destinationDomain, mintRecipient and burnToken.
  const response = await client.createContractExecutionTransaction({
    walletId: walletId, // '<WALLET_ID>',
    abiFunctionSignature: 'depositForBurn(uint256,uint32,bytes32,address)',
    abiParameters: [
      amountWithDecimals,
      circleDomain,
      encodedDestinationAddress,
      '0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238',
    ],
    contractAddress: '0x9f3B8679c73C2Fef8b59B4f3444d4e156fb70AA5',
    fee: {
      type: 'level',
      config: {
        feeLevel: 'MEDIUM',
      },
    },
  });

  return response;
}

(async () => {
  const amountWithDecimalsStr = '1000000';

  try {
    // mint and burn
    const depositForBurnResponse = await depositForBurn(walletEthSepolia1Id, amountWithDecimalsStr);
    console.log(depositForBurnResponse);
  } catch (error) {
    console.error('Error deposit for burn: ', error);
  }
})();
