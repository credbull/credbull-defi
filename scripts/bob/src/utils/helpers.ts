import { Database } from '@credbull/api';
import { SupabaseClient, createClient } from '@supabase/supabase-js';
import { Wallet, providers } from 'ethers';
import { SiweMessage, generateNonce } from 'siwe';

export const supabase = (opts?: { admin: boolean }) =>
  createClient<Database, 'public'>(
    process.env.NEXT_PUBLIC_SUPABASE_URL,
    opts?.admin ? process.env.SUPABASE_SERVICE_ROLE_KEY : process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
  );

export const login = async (client: SupabaseClient, opts?: { admin: boolean }) => {
  const body = JSON.stringify({
    email: opts?.admin ? process.env.ADMIN_EMAIL : process.env.BOB_EMAIL,
    password: opts?.admin ? process.env.ADMIN_PASSWORD : process.env.BOB_PASSWORD,
  });

  const signIn = await fetch(`${process.env.API_BASE_URL}/auth/api/sign-in`, { method: 'POST', body, ...headers() });
  return (await signIn.json()) as { accessToken: string; userId: string };
};

export const headers = (session?: { accessToken: string }) => {
  return {
    headers: {
      'Content-Type': 'application/json',
      ...(session?.accessToken ? { Authorization: `Bearer ${session.accessToken}` } : {}),
    },
  };
};

export const linkWalletMessage = async (address: string) => {
  const preMessage = new SiweMessage({
    domain: 'localhost:3000',
    address,
    statement: 'By connecting your wallet, you agree to the Terms of Service and Privacy Policy.',
    uri: 'http://localhost:3000',
    version: '1',
    chainId: Number(process.env.NEXT_PUBLIC_TARGET_NETWORK_ID),
    nonce: generateNonce(),
  });

  return preMessage.prepareMessage();
};

export const signer = (privateKey: string) => {
  return new Wallet(privateKey, new providers.JsonRpcProvider(process.env.NEXT_PUBLIC_TARGET_NETWORK));
};
