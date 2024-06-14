import { CredbullSDK } from '../../../src/index';

import { login } from './api';
import { TestSigner } from './test-signer';

export type User = {
  email: string;
  password: string;
  id: string;
  accessToken: string;
  address: string;
  testSigner: TestSigner;
  sdk: CredbullSDK;
};

// Assembles a utility `User` instance, logged in and with all pertinent utilities populated.
export async function userFor(config: any, email: string, password: string, testSigner: TestSigner) {
  const { access_token: accessToken, user_id } = await login(config, email, password);
  const wallet = testSigner.getDelegate();
  const address = await wallet.getAddress();
  const sdk = new CredbullSDK(config.api.url, { accessToken }, wallet);

  return { email, password, id: user_id, accessToken, address, testSigner, sdk };
}
