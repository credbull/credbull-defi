import { Database } from '@credbull/api';
import { SupabaseClient, createClient } from '@supabase/supabase-js';
import crypto from 'crypto';
import { Wallet, ethers } from 'ethers';
import { SiweMessage, generateNonce } from 'siwe';

import { Schema } from './schema';

export const supabase = (config: any, opts?: { admin: boolean }) => {
  Schema.CONFIG_SUPABASE_URL.merge(opts?.admin ? Schema.CONFIG_SUPABASE_ADMIN : Schema.CONFIG_SUPABASE_ANONYMOUS).parse(
    config,
  );

  return createClient<Database, 'public'>(
    config.services.supabase.url,
    opts?.admin ? config.secret!.SUPABASE_SERVICE_ROLE_KEY! : config.secret!.SUPABASE_ANONYMOUS_KEY!,
  );
};

export const userByOrThrow = async (supabaseAdmin: SupabaseClient, email: string) => {
  const user = await userByOrUndefined(supabaseAdmin, email);
  if (!user) throw new Error('No User for ' + email);
  return user;
};

/**
 * Searches for the `email` User, returning `undefined` if not found.
 * Only throws an error in a unrecoverable scenario.
 *
 * @param supabaseAdmin A `SupabaseClient` with administrative access.
 * @param email The `string` email address. Must be valid.
 * @returns A `Promise` of a User `any` or `undefined` if not found.
 * @throws ZodError if `email` is not an email address.
 * @throws PostgrestError if there is an error searching for the User.
 * @throws AuthError if there is an error accessing the database.
 * @throws Error if there is a system error or if the result pagination mechanism is broken.
 */
export const userByOrUndefined = async (supabaseAdmin: SupabaseClient, email: string): Promise<any | undefined> => {
  Schema.EMAIL.parse(email);

  const pageSize = 1_000;
  const {
    data: { users },
    error,
  } = await supabaseAdmin.auth.admin.listUsers({ perPage: pageSize });
  if (error) throw error;
  if (users.length === pageSize) throw Error('Implement pagination');
  return users.find((u) => u.email === email);
};

export const deleteUserIfPresent = async (supabaseAdmin: SupabaseClient, email: string) => {
  await userByOrThrow(supabaseAdmin, email)
    .then((user) => {
      supabaseAdmin.auth.admin.deleteUser(user.id, false);
    })
    .catch((error) => {
      // Ignore.
    });
};

export const headers = (session?: Awaited<ReturnType<typeof login>>) => {
  return {
    headers: {
      'Content-Type': 'application/json',
      ...(session?.access_token ? { Authorization: `Bearer ${session.access_token}` } : {}),
    },
  };
};

export const login = async (
  config: any,
  opts?: { admin: boolean },
): Promise<{ access_token: string; user_id: string }> => {
  Schema.CONFIG_API_URL.parse(config);

  let _email: string, _password: string;
  if (opts?.admin) {
    Schema.CONFIG_USER_ADMIN.parse(config);
    _email = config.users.admin.email_address;
    _password = config.secret!.ADMIN_PASSWORD!;
  } else {
    Schema.CONFIG_USER_BOB.parse(config);
    _email = config.users.bob.email_address;
    _password = config.secret!.BOB_PASSWORD!;
  }

  const body = JSON.stringify({ email: _email, password: _password });

  let signIn;

  try {
    signIn = await fetch(`${config.api.url}/auth/api/sign-in`, { method: 'POST', body, ...headers() });
  } catch (error) {
    console.error('Network error or server is down:', error);
    throw error;
  }

  if (!signIn.ok) {
    console.error(`HTTP error! status: ${signIn.status}`);
    throw new Error(`Failed to login: ${signIn.statusText}`);
  }

  const data = await signIn.json();
  console.log(`sign in response: ${JSON.stringify(data)}`);
  return data;
};

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

export const signer = (config: any, privateKey: string) => {
  Schema.CONFIG_ETHERS_URL.parse(config);
  return new Wallet(privateKey, new ethers.providers.JsonRpcProvider(config.services.ethers.url));
};

export const generateAddress = () => {
  const id = crypto.randomBytes(32).toString('hex');
  const privateKey = '0x' + id;

  const wallet = new Wallet(privateKey);
  return wallet.address;
};

export const generatePassword = (
  length = 15,
  characters = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz~!@-#$',
) => {
  return Array.from(crypto.getRandomValues(new Uint32Array(length)))
    .map((x) => characters[x % characters.length])
    .join('');
};

export function parseEmail(email: string) {
  Schema.EMAIL.parse(email);
}

export function parseEmailOptional(email?: string | null) {
  Schema.EMAIL_OPTIONAL.parse(email);
}

export function parseAddress(address: string) {
  Schema.ADDRESS.parse(address);
}

export function parseUpsideVault(upsideVaultSpec?: string) {
  Schema.UPSIDE_VAULT_SPEC.optional().parse(upsideVaultSpec);
}

export function generateRandomEmail(prefix: string): string {
  const randomString = Math.random().toString(36).substring(2, 10); // Generates a random string
  const domain = '@credbull.io';
  return `${prefix}+${randomString}${domain}`;
}
