// Import & Initialize

/* eslint-disable @typescript-eslint/no-var-requires */
const web3 = require('web3');
const { initiateDeveloperControlledWalletsClient } = require('@circle-fin/developer-controlled-wallets');
require('dotenv').config({ path: '../.env' }); // Adjust the path based on your folder structure
/* eslint-enable @typescript-eslint/no-var-requires */

const entitySecret = process.env.CIRCLE_WEB3_ENTITY_SECRET;
const apiKey = process.env.CIRCLE_WEB3_API_KEY;

const client = initiateDeveloperControlledWalletsClient({
  apiKey: apiKey,
  entitySecret: entitySecret,
});

async function getDepositTransaction() {
  const depositTxn = 'e560fb00-e1bf-5423-8c05-e62818f3d8c8'; // from depositForBurn

  const response = await client.getTransaction({
    id: depositTxn,
  });

  // Access the transaction object safely
  if (response && response.data && response.data.transaction) {
    return response.data.transaction; // Return the transaction object
  } else {
    throw new Error('Transaction data not found in response');
  }
}

async function createMessageBytesAndHash(transaction) {
  // TODO: fails with Error in fetch-attestation: TypeError: Cannot read properties of undefined (reading 'requestManager')
  if (!transaction.txHash) {
    throw new Error('Transaction hash (txHash) is missing from the transaction data');
  }

  // get messageBytes from EVM logs using txHash of the transaction.
  const transactionReceipt = await web3.eth.getTransactionReceipt(transaction.txHash); // TODO - error  message: 'value at "/0" is required'
  const eventTopic = web3.utils.keccak256('MessageSent(bytes)');
  const log = transactionReceipt.logs.find((l) => l.topics[0] === eventTopic);
  const messageBytes = web3.eth.abi.decodeParameters(['bytes'], log.data)[0];
  const messageHash = web3.utils.keccak256(messageBytes);

  return messageHash;
}

async function getAttestationResponse() {
  // Get attestation signature from iris-api.circle.com
  let attestationResponse = { status: 'pending' };

  while (attestationResponse.status != 'complete') {
    const response = await fetch(`https://iris-api-sandbox.circle.com/attestations/${messageHash}`);
    attestationResponse = await response.json();
    await new Promise((r) => setTimeout(r, 2000));
  }
}

(async () => {
  try {
    const depositTxnResponse = await getDepositTransaction();
    console.log(depositTxnResponse);

    const createMessageBytesAndHashResponse = await createMessageBytesAndHash(depositTxnResponse);
    console.log(createMessageBytesAndHashResponse);
  } catch (error) {
    console.error('Error in fetch-attestation:', error);
  }
})();
