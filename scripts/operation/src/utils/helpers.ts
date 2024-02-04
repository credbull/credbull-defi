import { Database } from '@credbull/api';
import { createClient } from '@supabase/supabase-js';
import { Wallet, providers } from 'ethers';
import { SiweMessage, generateNonce } from 'siwe';

export const supabase = (opts?: { admin: boolean }) =>
  createClient<Database, 'public'>(
    process.env.NEXT_PUBLIC_SUPABASE_URL,
    opts?.admin ? process.env.SUPABASE_SERVICE_ROLE_KEY : process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
  );

export const headers = (session?: Awaited<ReturnType<typeof login>>) => {
  return {
    headers: {
      'Content-Type': 'application/json',
      ...(session?.access_token ? { Authorization: `Bearer ${session.access_token}` } : {}),
    },
  };
};

export const login = async (opts?: { admin: boolean }): Promise<{ access_token: string; user_id: string }> => {
  const body = JSON.stringify({
    email: opts?.admin ? process.env.ADMIN_EMAIL : process.env.BOB_EMAIL,
    password: opts?.admin ? process.env.ADMIN_PASSWORD : process.env.BOB_PASSWORD,
  });

  const signIn = await fetch(`${process.env.API_BASE_URL}/auth/api/sign-in`, { method: 'POST', body, ...headers() });
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
  return new Wallet(privateKey, new providers.JsonRpcProvider(process.env.NEXT_PUBLIC_TARGET_NETWORK));
};
