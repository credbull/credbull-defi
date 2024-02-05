import {
  CredbullUpsideVault__factory,
  CredbullVault__factory,
  MockStablecoin__factory,
  MockToken__factory,
} from '@credbull/contracts';
import { formatEther, parseEther } from 'ethers/lib/utils';

import { headers, login, signer, supabase } from './utils/helpers';

export const main = (scenarios: { upside: boolean }) => {
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

    // console.log('Bob: queries for existing vaults.');
    const vaultsResponse = await fetch(`${process.env.API_BASE_URL}/vaults/current`, {
      method: 'GET',
      ...bobHeaders,
    });

    const vaults = await vaultsResponse.json();

    console.log('Bob: queries for existing vaults. - OK');

    const vaultAddress = vaults[0]['data'][scenarios.upside ? 0 : 1].address;
    const strategyAddress = vaults[0]['data'][0].strategy_address;
    const usdcAddress = vaults[0]['data'][0].asset_address;

    const usdc = MockStablecoin__factory.connect(usdcAddress, bobSigner);
    const innerVault = CredbullVault__factory.connect(vaultAddress, bobSigner);
    const mintTx = await usdc.mint(vaultAddress, parseEther('1000'));
    await mintTx.wait();

    const balanceInner = await innerVault.balanceOf(bobSigner.address);
    const approveTTx = await innerVault.approve(strategyAddress, balanceInner);
    await approveTTx.wait();

    const vault = CredbullUpsideVault__factory.connect(strategyAddress, bobSigner);

    const shares = await vault.balanceOf(bobSigner.address);
    const approveSTx = await vault.approve(strategyAddress, shares);
    await approveSTx.wait();

    const redeemTx = await vault['redeem(uint256,address,address,bool)'](
      shares,
      bobSigner.address,
      bobSigner.address,
      Boolean(scenarios.upside),
      {
        gasLimit: 10000000,
      },
    );

    await redeemTx.wait();
    console.log('Bob: deposits his USDC in the vault. - OK');

    const balanceOfInner = await innerVault.balanceOf(bobSigner.address);
    const balanceOfUSDC = await usdc.balanceOf(bobSigner.address);
    console.log(`Bob: has ${formatEther(balanceOfInner)} sToken. - OK`);
    console.log(`Bob: has ${formatEther(balanceOfUSDC)} USDC. - OK`);

    if (scenarios.upside) {
      const client = supabase({ admin: true });
      const addresses = await client.from('contracts_addresses').select();
      if (addresses.error) return addresses;

      const tokenAddress = addresses.data.find((a) => a.contract_name === 'MockToken');
      if (!tokenAddress) throw new Error('Token address not found');

      const token = MockToken__factory.connect(tokenAddress.address, bobSigner);
      const balanceOfToken = await token.balanceOf(bobSigner.address);
      const balanceOf = await vault.balanceOf(bobSigner.address);
      console.log(`Bob: has ${formatEther(balanceOf)} cToken. - OK`);
      console.log(`Bob: has ${formatEther(balanceOfToken)} mToken. - OK`);
    }

    console.log('\n');
    console.log('=====================================');
    console.log('\n');
  }, 1000);
};
