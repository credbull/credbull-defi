import { Wallet, ethers } from 'ethers';
import { SiweMessage, generateNonce } from 'siwe';

import { Schema } from './schema';

export const linkWalletMessage = async (config: any, signer: Wallet) => {
  Schema.CONFIG_APP_URL.parse(config);

  let appUrl = new URL(config.app.url);
  const chainId = await signer.getChainId();
  const preMessage = new SiweMessage({
    domain: appUrl.host,
    address: signer.address,
    statement: 'By connecting your wallet, you agree to the Terms of Service and Privacy Policy.',
    uri: appUrl.href,
    version: '1',
    chainId,
    nonce: generateNonce(),
  });

  return preMessage.prepareMessage();
};

export const signerFor = (config: any, privateKey: string) => {
  Schema.CONFIG_ETHERS_URL.parse(config);
  return new Wallet(privateKey, new ethers.providers.JsonRpcProvider(config.services.ethers.url));
};
