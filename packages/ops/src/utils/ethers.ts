import { Signer, Wallet, ethers } from 'ethers';
import { SiweMessage, generateNonce } from 'siwe';

import { Schema } from './schema';

export async function linkWalletMessage(config: any, signer: Wallet): Promise<string> {
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
}

export function signerFor(config: any, privateKey: string): Signer {
  Schema.CONFIG_ETHERS_URL.parse(config);
  return new Wallet(privateKey, new ethers.providers.JsonRpcProvider(config.services.ethers.url));
}
