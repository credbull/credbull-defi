import {
  CredbullFixedYieldVault,
  CredbullFixedYieldVaultWithUpside,
  MockStablecoin__factory,
} from '@credbull/contracts';
import { config } from 'dotenv';
import { BigNumber, Signer, Wallet, providers } from 'ethers';

config();

export async function whtielist(address: string, user_id: string) {
  const { access_token } = await login(process.env.ADMIN_EMAIL || '', process.env.ADMIN_PASSWORD || '');

  const whistelistRes = await fetch(`${process.env.BASE_URL}/accounts/whitelist`, {
    method: 'POST',
    body: JSON.stringify({ address, user_id }),
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${access_token}` },
  });

  await whistelistRes.json();
}

export async function login(email: string, password: string) {
  const res = await fetch(`${process.env.BASE_URL}/auth/api/sign-in`, {
    method: 'POST',
    body: JSON.stringify({ email, password }),
    headers: { 'Content-Type': 'application/json' },
  });

  return await res.json();
}

export async function __mockMint(
  to: string,
  amount: BigNumber,
  vault: CredbullFixedYieldVault | CredbullFixedYieldVaultWithUpside,
  signer: Signer | providers.Provider,
) {
  const assetAddress = await vault.asset();
  const asset = MockStablecoin__factory.connect(assetAddress, signer);

  await asset.mint(to, amount);
}

export async function toggleMaturityCheck(
  vault: CredbullFixedYieldVault | CredbullFixedYieldVaultWithUpside,
  value: boolean,
) {
  const adminSigner = await getAdminSigner();
  await vault.connect(adminSigner).toggleMaturityCheck(value);
}

export async function toggleWindowCheck(
  vault: CredbullFixedYieldVault | CredbullFixedYieldVaultWithUpside,
  value: boolean,
) {
  const adminSigner = await getAdminSigner();
  await vault.connect(adminSigner).toggleWindowCheck(value);
}

export async function getAdminSigner() {
  return new Wallet(process.env.ADMIN_PRIVATE_KEY, new providers.JsonRpcProvider(`http://localhost:8545`));
}
