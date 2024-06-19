import { Signer, Wallet, ethers } from 'ethers';

import { Schema } from './schema';

// Signs the `email` user into the Credbull API.
export async function login(config: any, email: string, password: string): Promise<any> {
  Schema.CONFIG_API_URL.parse(config);
  Schema.EMAIL.parse(email);
  Schema.NON_EMPTY_STRING.parse(password);

  return fetch(`${config.api.url}/auth/api/sign-in`, {
    method: 'POST',
    body: JSON.stringify({ email, password }),
    headers: { 'Content-Type': 'application/json' },
  }).then((response) => {
    return response.json();
  });
}

// Creates a new `Signer` (actually a `Wallet`) for `privateKey`.
export const signerFor = (config: any, privateKey: string): Signer => {
  Schema.CONFIG_API_URL.parse(config);
  Schema.NON_EMPTY_STRING.parse(privateKey);

  return new Wallet(privateKey, new ethers.providers.JsonRpcProvider(config.api.url));
};
