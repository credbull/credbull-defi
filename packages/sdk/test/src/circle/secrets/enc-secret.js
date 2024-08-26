/* eslint-disable @typescript-eslint/no-var-requires */
const { getPublicKey } = require('./gen-devWallet-pubKey.js');
const forge = require('node-forge');
require('dotenv').config();
/* eslint-enable @typescript-eslint/no-var-requires */

async function encryptSecret() {
  try {
    // Call getPublicKey to get the public key PEM
    const publicKeyPem = await getPublicKey();

    console.log('here...');
    console.log('secret=', process.env.CIRCLE_WEB3_ENTITY_SECRET);
    console.log('there');

    const entitySecret = forge.util.hexToBytes(process.env.CIRCLE_WEB3_ENTITY_SECRET);

    // Convert the PEM-formatted public key to a Forge public key object
    const publicKey = forge.pki.publicKeyFromPem(publicKeyPem);

    // Encrypt the entity secret using the public key with RSA-OAEP and SHA-256
    const encryptedData = publicKey.encrypt(entitySecret, 'RSA-OAEP', {
      md: forge.md.sha256.create(),
      mgf1: {
        md: forge.md.sha256.create(),
      },
    });

    // Encode the encrypted data in base64
    const encryptedDataBase64 = forge.util.encode64(encryptedData);

    console.log('Encrypted Data:', encryptedDataBase64);
  } catch (error) {
    console.error('Error during encryption:', error);
  }
}

// Call the function to execute the encryption
encryptSecret();
