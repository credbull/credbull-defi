import {
  CredbullFixedYieldVault,
  CredbullFixedYieldVaultWithUpside,
  MockStablecoin__factory,
} from '@credbull/contracts';
import * as ChildProcess from 'child_process';
import { config } from 'dotenv';
import { BigNumber, Signer, Wallet, providers, utils } from 'ethers';
import path from 'path';

config();

export const TRASH_ADDRESS = '0xcabE80b332Aa9d900f5e32DF51cb0Bc5b276c556';

export const generateAddress = (name: string) => {
  const hash = utils.id(name);
  const hashBuffer = Buffer.from(hash.slice(2), 'hex');
  const paddedHash = utils.hexlify(utils.zeroPad(hashBuffer, 32));
  const privateKey = `${utils.hexlify(paddedHash)}`;
  const wallet = new Wallet(privateKey);
  return { pkey: privateKey, address: wallet.address };
};

function envCleanup(existing: any, newEnv: any) {
  //Find keys of newEnv that are in existing and replace it with the new value
  for (const key in newEnv) {
    if (Object.prototype.hasOwnProperty.call(existing, key)) {
      if (existing.hasOwnProperty(key)) {
        existing[key] = newEnv[key];
      }
    } else {
      existing[key] = newEnv[key];
    }
  }

  return existing;
}

export async function createFixedYieldVault(envs?: any) {
  let cleanedUpEnvs = JSON.parse(JSON.stringify(process.env));
  if (envs !== undefined) {
    cleanedUpEnvs = JSON.parse(JSON.stringify(envCleanup(cleanedUpEnvs, envs)));
  }

  ChildProcess.execSync('yarn op --create-vault matured', {
    env: { ...cleanedUpEnvs },
    cwd: path.resolve(__dirname, '../../../../scripts/operation'),
  });
}

export async function createUpsideVaultVault(envs?: any) {
  let cleanedUpEnvs = JSON.parse(JSON.stringify(process.env));
  if (envs !== undefined) {
    cleanedUpEnvs = JSON.parse(JSON.stringify(envCleanup(cleanedUpEnvs, envs)));
  }

  ChildProcess.execSync('yarn op --create-vault matured,upside upsideVault:self', {
    env: { ...cleanedUpEnvs },
    cwd: path.resolve(__dirname, '../../../../scripts/operation'),
  });
}

export async function getVaultEntities(id: string) {
  const { access_token } = await login(process.env.ADMIN_EMAIL_SDK || '', process.env.ADMIN_PASSWORD_SDK || '');

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
  const { access_token } = await login(process.env.ADMIN_EMAIL_SDK || '', process.env.ADMIN_PASSWORD_SDK || '');

  console.log(address);
  const whistelistRes = await fetch(`${process.env.BASE_URL}/accounts/whitelist`, {
    method: 'POST',
    body: JSON.stringify({ address, user_id }),
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${access_token}` },
  });

  const res = await whistelistRes.json();
  return res;
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
  return new Wallet(process.env.ADMIN_PRIVATE_KEY_SDK || '', new providers.JsonRpcProvider(`http://localhost:8545`));
}

export async function sleep(ms: number) {
  new Promise((resolve) => setTimeout(resolve, ms));
}
