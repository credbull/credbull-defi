import { CredbullFixedYieldVault__factory, MockStablecoin__factory } from '@credbull/contracts';
import { formatEther, parseUnits } from 'ethers/lib/utils';

import { headers, login } from './utils/api';
import { loadConfiguration } from './utils/config';
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

    const usdc = MockStablecoin__factory.connect(usdcAddress, bobSigner);
    const vault = CredbullFixedYieldVault__factory.connect(vaultAddress, bobSigner);
    const mintTx = await usdc.mint(vaultAddress, parseUnits('1000', 'mwei'));
    await mintTx.wait();

    const shares = await vault.balanceOf(bobSigner.address);
    const approveTTx = await vault.approve(vaultAddress, shares);
    await approveTTx.wait();

    const redeemTx = await vault.redeem(shares, bobSigner.address, bobSigner.address, {
      gasLimit: 10000000,
    });

    await redeemTx.wait();
    console.log('Bob: redeems. - OK');

    const balanceOfInner = await vault.balanceOf(bobSigner.address);
    const balanceOfUSDC = await usdc.balanceOf(bobSigner.address);

    console.log(`Bob: has ${formatEther(balanceOfInner)} sToken. - OK`);
    console.log(`Bob: has ${formatEther(balanceOfUSDC)} USDC. - OK`);

    console.log('\n');
    console.log('=====================================');
    console.log('\n');
  }, 1000);
};
