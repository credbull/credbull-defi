import {
  CredbullFixedYieldVaultWithUpside__factory,
  MockStablecoin__factory,
  MockToken__factory,
} from '@credbull/contracts';
import { formatEther, parseUnits } from 'ethers/lib/utils';

import { headers, login } from './utils/api';
import { loadConfiguration } from './utils/config';
import { supabaseAdminClient } from './utils/database';
import { linkWalletMessage, signerFor } from './utils/ethers';

export const main = () => {
  setTimeout(async () => {
    console.log('\n');
    console.log('=====================================');
    console.log('\n');
    const config = loadConfiguration();

    // console.log('Bob: retrieves a session through api.');
    const bob = await login(config);

    const bobHeaders = headers(bob);
    console.log('Bob: retrieves a session through api. - OK');

    // console.log('Bob: signs a message with his wallet.');
    const bobSigner = signerFor(config, config.secret!.BOB_PRIVATE_KEY!);
    const message = await linkWalletMessage(config, bobSigner);
    const signature = await bobSigner.signMessage(message);
    console.log('Bob: signs a message with his wallet. - OK');

    // console.log('Bob: sends the signed message to Credbull so that he can be KYC`ed.');
    await fetch(`${config.api.url}/accounts/link-wallet`, {
      method: 'POST',
      body: JSON.stringify({ message, signature, discriminator: config.users.bob.email_address }),
      ...bobHeaders,
    });
    console.log('Bob: sends the signed message to Credbull so that he can be KYC`ed. - OK');

    // console.log('Admin: receives the approval and KYCs Bob.');
    const admin = await login({ admin: true });
    const adminHeaders = headers(admin);

    await fetch(`${config.api.url}/accounts/whitelist`, {
      method: 'POST',
      body: JSON.stringify({ user_id: bob.user_id, address: bobSigner.address }),
      ...adminHeaders,
    });
    console.log('Admin: receives the approval and KYCs Bob. - OK');

    // console.log('Bob: queries for existing vaults.');
    const vaultsResponse = await fetch(`${config.api.url}/vaults/current`, {
      method: 'GET',
      ...bobHeaders,
    });

    const vaults = await vaultsResponse.json();

    console.log('Bob: queries for existing vaults. - OK');

    const vaultAddress = vaults['data'][0].address;
    const usdcAddress = vaults['data'][0].asset_address;

    const usdc = MockStablecoin__factory.connect(usdcAddress, bobSigner);
    const mintTx = await usdc.mint(bobSigner.address, parseUnits('1000', 'mwei'));
    await mintTx.wait();
    console.log('mint usdc - OK');

    const approveTx = await usdc.approve(vaultAddress, parseUnits('1000', 'mwei'));
    await approveTx.wait();
    console.log('Bob: gives the approval to the vault to swap it`s USDC. - OK');

    const client = supabaseAdminClient(config);
    const addresses = await client.from('contracts_addresses').select();
    if (addresses.error) return addresses;

    const tokenAddress = addresses.data.find((a) => a.contract_name === 'MockToken');
    if (!tokenAddress) throw new Error('Token address not found');

    const token = MockToken__factory.connect(tokenAddress.address, bobSigner);
    const tokenTx = await token.mint(bobSigner.address, parseUnits('1000', 'mwei'));
    await tokenTx.wait();
    console.log('token usdc - OK');

    const approveTTx = await token.approve(vaultAddress, parseUnits('1000', 'mwei'));
    await approveTTx.wait();
    console.log('Bob: gives the approval to the vault to swap it`s cToken. - OK');

    const vault = CredbullFixedYieldVaultWithUpside__factory.connect(vaultAddress, bobSigner);
    const depositTx = await vault.deposit(parseUnits('1000', 'mwei'), bobSigner.address, { gasLimit: 10000000 });
    await depositTx.wait();
    console.log('Bob: deposits his USDC in the vault. - OK');

    console.log(`Vault: has ${formatEther(await token.balanceOf(vaultAddress))} cToken. - OK`);
    console.log(`Bob: has ${(await vault.balanceOf(bobSigner.address)).div(10 ** 6)} SHARES. - OK`);

    console.log('\n');
    console.log('=====================================');
    console.log('\n');
  }, 1000);
};
