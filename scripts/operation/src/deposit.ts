import { CredbullFixedYieldVault__factory, MockStablecoin__factory } from '@credbull/contracts';
import { parseUnits } from 'ethers/lib/utils';

import { headers, linkWalletMessage, login, signer } from './utils/helpers';

export const main = () => {
  setTimeout(async () => {
    console.log('\n');
    console.log('=====================================');
    console.log('\n');

    // console.log('Bob: retrieves a session through api.');
    const bob = await login();

    const bobHeaders = headers(bob);
    console.log('Bob: retrieves a session through api. - OK');

    // console.log('Bob: signs a message with his wallet.');
    const bobSigner = signer(process.env.BOB_PRIVATE_KEY);
    const message = await linkWalletMessage(bobSigner);
    const signature = await bobSigner.signMessage(message);
    console.log('Bob: signs a message with his wallet. - OK');

    // console.log('Bob: sends the signed message to Credbull so that he can be KYC`ed.');
    await fetch(`${process.env.API_BASE_URL}/accounts/link-wallet`, {
      method: 'POST',
      body: JSON.stringify({ message, signature, discriminator: 'bob@partner.com' }),
      ...bobHeaders,
    });
    console.log('Bob: sends the signed message to Credbull so that he can be KYC`ed. - OK');

    // console.log('Admin: receives the approval and KYCs Bob.');
    const admin = await login({ admin: true });
    const adminHeaders = headers(admin);
    const adminSigner = signer(process.env.ADMIN_PRIVATE_KEY);

    await fetch(`${process.env.API_BASE_URL}/accounts/whitelist`, {
      method: 'POST',
      body: JSON.stringify({ user_id: bob.user_id, address: bobSigner.address }),
      ...adminHeaders,
    });
    console.log('Admin: receives the approval and KYCs Bob. - OK');

    // console.log('Bob: queries for existing vaults.');
    const vaultsResponse = await fetch(`${process.env.API_BASE_URL}/vaults/current`, {
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

    const approveTx = await usdc.approve(vaultAddress, parseUnits('1000', 'mwei'));
    await approveTx.wait();
    console.log('Bob: gives the approval to the vault to swap it`s USDC. - OK');

    // console.log('Bob: deposits his USDC in the vault.');
    const vault = CredbullFixedYieldVault__factory.connect(vaultAddress, bobSigner);

    const toggleTx = await vault.connect(adminSigner).toggleWindowCheck(false);
    await toggleTx.wait();

    const depositTx = await vault.deposit(parseUnits("1000", "mwei"), bobSigner.address, { gasLimit: 10000000 });
    await depositTx.wait();
    console.log('Bob: deposits his USDC in the vault. - OK');

    const balanceOf = await vault.balanceOf(bobSigner.address);
    console.log(`Bob: has ${balanceOf.div(10 ** 6)} USDC deposited in the vault. - OK`);

    console.log('\n');
    console.log('=====================================');
    console.log('\n');
  }, 1000);
};
