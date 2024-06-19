import {
  CredbullFixedYieldVaultWithUpside__factory,
  MockStablecoin__factory,
  MockToken__factory,
} from '@credbull/contracts';
import { formatEther, parseUnits } from 'ethers/lib/utils';

import { headers, login } from './utils/api';
import { loadConfiguration } from './utils/config';
import { supabaseAdminClient } from './utils/database';
import { signerFor } from './utils/ethers';

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

    // console.log('Bob: queries for existing vaults.');
    const vaultsResponse = await fetch(`${config.api.url}/vaults/current`, {
      method: 'GET',
      ...bobHeaders,
    });

    const vaults = await vaultsResponse.json();

    console.log('Bob: queries for existing vaults. - OK');

    const vaultAddress = vaults['data'][0].address;
    const usdcAddress = vaults['data'][0].asset_address;

    const client = supabaseAdminClient(config);
    const addresses = await client.from('contracts_addresses').select();
    if (addresses.error) return addresses;

    const tokenAddress = addresses.data.find((a) => a.contract_name === 'MockToken');
    if (!tokenAddress) throw new Error('Token address not found');

    const usdc = MockStablecoin__factory.connect(usdcAddress, bobSigner);
    const token = MockToken__factory.connect(tokenAddress.address, bobSigner);
    const vault = CredbullFixedYieldVaultWithUpside__factory.connect(vaultAddress, bobSigner);
    const mintTx = await usdc.mint(vaultAddress, parseUnits('1000', 'mwei'));
    await mintTx.wait();

    const shares = await vault.balanceOf(bobSigner.address);

    let balanceOfToken = await token.balanceOf(vaultAddress);
    let balanceOfUSDC = await usdc.balanceOf(vaultAddress);
    console.log(`Bob: balance before redeem ${formatEther(shares)} sToken - OK`);
    console.log(`Vault: balance before redeem ${formatEther(balanceOfToken)} cToken - OK`);
    console.log(`Vault: balance before redeem ${formatEther(balanceOfUSDC)} USDC - OK`);

    const redeemTx = await vault.redeem(shares, bobSigner.address, bobSigner.address, {
      gasLimit: 10000000,
    });

    await redeemTx.wait();
    console.log('Bob: redeems. - OK');

    const balanceOf = await vault.balanceOf(bobSigner.address);
    balanceOfToken = await token.balanceOf(vaultAddress);
    balanceOfUSDC = await usdc.balanceOf(vaultAddress);

    console.log(`Bob: has ${formatEther(balanceOf)} sToken. - OK`);
    console.log(`Vault: has ${formatEther(balanceOfUSDC)} USDC. - OK`);
    console.log(`Vault: has ${formatEther(balanceOfToken)} cToken. - OK`);

    console.log('\n');
    console.log('=====================================');
    console.log('\n');
  }, 1000);
};
