import { type PublicClient, getPublicClient } from '@wagmi/core';
import { type WalletClient, getWalletClient } from '@wagmi/core';
import { providers } from 'ethers';
import { type HttpTransport } from 'viem';

export function publicClientToProvider(publicClient: PublicClient) {
  const { chain, transport } = publicClient;
  const network = {
    chainId: chain.id,
    name: chain.name,
    ensAddress: chain.contracts?.ensRegistry?.address,
  };
  if (transport.type === 'fallback')
    return new providers.FallbackProvider(
      (transport.transports as ReturnType<HttpTransport>[]).map(
        ({ value }) => new providers.JsonRpcProvider(value?.url, network),
      ),
    );
  return new providers.JsonRpcProvider(transport.url, network);
}

/** Action to convert a viem Public Client to an ethers.js Provider. */
export function getEthersProvider({ chainId }: { chainId?: number } = {}) {
  const publicClient = getPublicClient({ chainId });
  return publicClientToProvider(publicClient);
}

export function walletClientToSigner(walletClient: WalletClient) {
  const { account, chain, transport } = walletClient;
  const network = {
    chainId: chain.id,
    name: chain.name,
    ensAddress: chain.contracts?.ensRegistry?.address,
  };
  const provider = new providers.Web3Provider(transport, network);
  const signer = provider.getSigner(account.address);
  return signer;
}

/** Action to convert a viem Wallet Client to an ethers.js Signer. */
export async function getEthersSigner({ chainId }: { chainId?: number } = {}) {
  const walletClient = await getWalletClient({ chainId });
  console.log(walletClient);
  if (!walletClient) return undefined;
  return walletClientToSigner(walletClient);
}

export const decodeError = (contract: any, err: string) => {
  console.log('in decode error');
  const contractInterface = contract.interface;
  const selecter = err.slice(0, 10);
  const res = contractInterface.decodeErrorResult(selecter, err);
  const errorName = contractInterface.getError(selecter).name;
  console.log(errorName);
  console.log(res.toString());
};
