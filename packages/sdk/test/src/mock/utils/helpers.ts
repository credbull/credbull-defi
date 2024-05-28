import crypto from 'crypto';
import { BigNumber, Signer, Wallet, providers } from 'ethers';

import { CredbullFixedYieldVault, MockStablecoin__factory } from '@credbull/contracts';

export const headers = (session?: Awaited<ReturnType<typeof login>>) => {
  return {
    headers: {
      'Content-Type': 'application/json',
      ...(session?.access_token ? { Authorization: `Bearer ${session.access_token}` } : {}),
    },
  };
};

export const login = async (email: string, password: string): Promise<{ access_token: string; user_id: string }> => {
  const body = JSON.stringify({
    email: email,
    password: password,
  });

  const signIn = await fetch(`${process.env.API_BASE_URL}/auth/api/sign-in`, { method: 'POST', body, ...headers() });
  return signIn.json();
};

export const signer = (privateKey: string) => {
  return new Wallet(privateKey, new providers.JsonRpcProvider(`${process.env.RPC_PROVIDER}`));
};

export const generateAddress = () => {
  const id = crypto.randomBytes(32).toString('hex');
  const privateKey = '0x' + id;

  const wallet = new Wallet(privateKey);
  return wallet.address;
};

export const generateSigner = () => {
  const id = crypto.randomBytes(32).toString('hex');
  const privateKey = '0x' + id;

  return new Wallet(privateKey, new providers.JsonRpcProvider(`${process.env.RPC_PROVIDER}`));
};

export const decodeError = (contract: any, err: string) => {
  const contractInterface = contract.interface;
  const selecter = err.slice(0, 10);
  const res = contractInterface.decodeErrorResult(selecter, err);
  const errorName = contractInterface.getError(selecter).name;
  console.log(errorName);
  console.log(res.toString());
};

export const __mockMint = async (
  to: string,
  amount: BigNumber,
  vault: CredbullFixedYieldVault,
  signer: Signer | providers.Provider,
) => {
  const assetAddress = await vault.asset();
  const asset = MockStablecoin__factory.connect(assetAddress, signer);

  await asset.mint(to, amount);
};
