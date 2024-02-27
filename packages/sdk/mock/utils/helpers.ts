import crypto from 'crypto';
import { Wallet, providers } from 'ethers';
import { SiweMessage, generateNonce } from 'siwe';


export const headers = (session?: Awaited<ReturnType<typeof login>>) => {
  return {
    headers: {
      'Content-Type': 'application/json',
      ...(session?.access_token ? { Authorization: `Bearer ${session.access_token}` } : {}),
    },
  };
};

export const login = async (email: string, password: string, opts?: { admin: boolean }): Promise<{ access_token: string; user_id: string }> => {
  const body = JSON.stringify({
    email: email,
    password: password
  });

  const signIn = await fetch(`http://localhost:3001/auth/api/sign-in`, { method: 'POST', body, ...headers() });
  return signIn.json();
};

export const linkWalletMessage = async (signer: Wallet) => {
  const chainId = await signer.getChainId();
  const preMessage = new SiweMessage({
    domain: 'localhost:3000',
    address: signer.address,
    statement: 'By connecting your wallet, you agree to the Terms of Service and Privacy Policy.',
    uri: 'http://localhost:3000',
    version: '1',
    chainId,
    nonce: generateNonce(),
  });

  return preMessage.prepareMessage();
};

export const signer = (privateKey: string) => {
  return new Wallet(privateKey,  new providers.JsonRpcProvider(`http://localhost:8545`));
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

  return new Wallet(privateKey, new providers.JsonRpcProvider(`http://localhost:8545`));
}

export const decodeError = (contract:any, err: String) => {
    const contractInterface = contract.interface;
    const selecter = err.slice(0, 10);
    const res = contractInterface.decodeErrorResult(selecter, err);
    const errorName = contractInterface.getError(selecter).name;
    console.log(errorName);
    console.log(res.toString());
}
