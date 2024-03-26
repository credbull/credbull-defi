import {
  CredbullFixedYieldVault,
  CredbullFixedYieldVaultWithUpside,
  MockStablecoin__factory,
} from '@credbull/contracts';
import * as ChildProcess from 'child_process';
import { config } from 'dotenv';
import { BigNumber, Signer, Wallet, providers } from 'ethers';
import path from 'path';

config();

export async function createFixedYieldVault() {
  ChildProcess.execSync('yarn op --create-vault matured', {
    cwd: path.resolve(__dirname, '../../../../scripts/operation'),
  });
}

export async function createUpsideVaultVault() {
  ChildProcess.execSync('yarn op --create-vault upside upsideVault:self', {
    cwd: path.resolve(__dirname, '../../../../scripts/operation'),
  });
}

export async function getVaultEntities(id: string) {
  const { access_token } = await login(process.env.ADMIN_EMAIL || '', process.env.ADMIN_PASSWORD || '');

  const res = await fetch(`${process.env.BASE_URL}/vaults/vault-entities/${id}`, {
    headers: { Authorization: `Bearer ${access_token}` },
  });

  return await res.json();
}

export async function distributeFixedYieldVault() {
  const res = await fetch(`${process.env.BASE_URL}/vaults/mature-outstanding`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${process.env.CRON_SECRET || ''}` },
  });
}

export async function whitelist(address: string, user_id: string) {
  const { access_token } = await login(process.env.ADMIN_EMAIL || '', process.env.ADMIN_PASSWORD || '');

  const whistelistRes = await fetch(`${process.env.BASE_URL}/accounts/whitelist`, {
    method: 'POST',
    body: JSON.stringify({ address, user_id }),
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${access_token}` },
  });

  const res = await whistelistRes.json();
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

export async function __mockMintToken(
  to: string,
  amount: BigNumber,
  vault: CredbullFixedYieldVaultWithUpside,
  signer: Signer | providers.Provider,
) {
  const tokenAddress = await vault.token();
  const token = MockStablecoin__factory.connect(tokenAddress, signer);

  await token.mint(to, amount);
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
