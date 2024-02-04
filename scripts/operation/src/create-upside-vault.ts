import { CredbullUpsideVaultFactory__factory } from '@credbull/contracts';

import { signer, supabase } from './utils/helpers';

// eslint-disable-next-line @typescript-eslint/no-unused-vars
export const main = (scenarios: object, params?: { baseVault: string; upsideVault: string; asset: string }) => {
  setTimeout(async () => {
    console.log('\n');
    console.log('=====================================');
    console.log('\n');

    if (!params?.asset) throw new Error('Asset address are required');
    if (!params?.baseVault || !params?.upsideVault) throw new Error('Base and Upside vault address are required');

    const supabaseClient = supabase({ admin: true });

    const addresses = await supabaseClient.from('contracts_addresses').select();
    if (addresses.error) return addresses;

    const factoryAddress = addresses.data.find((a) => a.contract_name === 'CredbullUpsideVaultFactory');
    if (!factoryAddress) throw new Error('Upside vault factory address not found');

    const tokenAddress = addresses.data.find((a) => a.contract_name === 'MockToken');
    if (!tokenAddress) throw new Error('Token address not found');

    const owner = signer(process.env.ADMIN_PRIVATE_KEY);

    const factory = CredbullUpsideVaultFactory__factory.connect(factoryAddress.address, owner);
    const tx = await factory.createUpsideVault(params?.baseVault, params?.upsideVault, params.asset);

    await tx.wait();

    const count = await factory.getTotalVaultCount();
    const vault = await factory.getVaultAtIndex(count.toNumber() - 1);

    console.log('Upside vault created: ', vault);

    await supabaseClient
      .from('vaults')
      .update({ strategy_address: vault })
      .in('address', [params?.baseVault, params?.upsideVault]);

    console.log('\n');
    console.log('=====================================');
    console.log('\n');
  }, 1000);
};
