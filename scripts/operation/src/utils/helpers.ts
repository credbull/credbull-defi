import { SupabaseClient, createClient } from '@supabase/supabase-js';
import crypto from 'crypto';
import { Wallet, providers } from 'ethers';
import { SiweMessage, generateNonce } from 'siwe';
import { z } from 'zod';

import { Database } from '@credbull/api';

const supabaseConfigParser = z.object({
  services: z.object({ supabase: z.object({ url: z.string().url() }) }),
  secret: z.object({
    SUPABASE_SERVICE_ROLE_KEY: z.string(),
    SUPABASE_ANONYMOUS_KEY: z.string(),
  })
});

export const supabase = (config: any, opts?: { admin: boolean }) => {
  supabaseConfigParser.parse(config)

  return createClient<Database, 'public'>(
    config.services.supabase.url,
    opts?.admin ? config.secret!.SUPABASE_SERVICE_ROLE_KEY! : config.secret!.SUPABASE_ANONYMOUS_KEY!,
  );
}

export const userByOrThrow = async (supabaseAdmin: SupabaseClient, email: string) => {
  const user = await userByOrUndefined(supabaseAdmin, email);
  if (!user) throw new Error('No User for ' + email);
  return user;
};

export const userByOrUndefined = async (supabaseAdmin: SupabaseClient, email: string): Promise<any> => {
  const pageSize = 1_000;
  const { data: { users }, error } = await supabaseAdmin.auth.admin.listUsers({ perPage: pageSize });
  if (error) throw error;
  if (users.length === pageSize) throw Error('Implement pagination');
  return users.find((u) => u.email === email);
};

export const deleteUserIfPresent = async (supabaseAdmin: SupabaseClient, email: string) => {
  await userByOrUndefined(supabaseAdmin, email)
    .then((user) => {
      supabaseAdmin.auth.admin.deleteUser(user.id, false);
    }).catch((error) => {
      // Ignore.
    });
}

export const headers = (session?: Awaited<ReturnType<typeof login>>) => {
  return {
    headers: {
      'Content-Type': 'application/json',
      ...(session?.access_token ? { Authorization: `Bearer ${session.access_token}` } : {}),
    },
  };
};

const adminLoginConfigParser = z.object({
  api: z.object({ url: z.string().url() }),
  users: z.object({ admin: z.object({ email_address: z.string().email() }) }),
  secret: z.object({ ADMIN_PASSWORD: z.string() })
});

const bobLoginConfigParser = z.object({
  api: z.object({ url: z.string().url() }),
  users: z.object({ bob: z.object({ email_address: z.string().email() }) }),
  secret: z.object({ BOB_PASSWORD: z.string() })
});

export const login = async (
  config: any,
  opts?: { admin: boolean }
): Promise<{ access_token: string; user_id: string }> => {
  let _email: string, _password: string;
  if (opts?.admin) {
    adminLoginConfigParser.parse(config);
    _email = config.users.admin.email_address;
    _password = config.secret!.ADMIN_PASSWORD!;
  } else {
    bobLoginConfigParser.parse(config);
    _email = config.users.bob.email_address;
    _password = config.secret!.BOB_PASSWORD!;
  }

  const body = JSON.stringify({ email: _email, password: _password });
  const signIn = await fetch(`${config.api.url}/auth/api/sign-in`, { method: 'POST', body, ...headers() });
  return signIn.json();
};

const linkWalletConfigParser = z.object({ app: z.object({ url: z.string().url() }) });

export const linkWalletMessage = async (config: any, signer: Wallet) => {
  linkWalletConfigParser.parse(config);

  let appUrl = new URL(config.app.url)
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

const signerConfigParser = z.object({ services: z.object({ ethers: z.object({ url: z.string().url() }) }) });

export const signer = (config: any, privateKey: string) => {
  signerConfigParser.parse(config);
  return new Wallet(privateKey, new providers.JsonRpcProvider(config.services.ethers.url));
};

export const generateAddress = () => {
  const id = crypto.randomBytes(32).toString('hex');
  const privateKey = '0x' + id;

  const wallet = new Wallet(privateKey);
  return wallet.address;
};
