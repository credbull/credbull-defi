'use server';

import { cookies } from 'next/headers';

import { createClient as createCredbull } from '@/clients/credbull-api.client';
import { createClient as createSuabase } from '@/clients/supabase.server';

export const whitelistAddress = async (address: string) => {
  const supabase = createSuabase(cookies());
  const credbullApi = createCredbull(supabase);

  const auth = await supabase.auth.getSession();
  const user_id = auth.data.session!.user.id;

  return credbullApi.whitelistAddress({ address, user_id });
};

export const exportVaultsToSupabase = async (vaultData: any) => {
  console.log('in exportvaults');
  const supabase = createSuabase(cookies());

  // await supabase.from('vaults').delete().in('address', vaultData.address);

  console.log(await supabase.from('vaults').select());

  const opened_at = new Date();
  opened_at.setTime(vaultData.opened_at).toString();

  const closed_at = new Date();
  closed_at.setTime(vaultData.closed_at).toString();

  const dbData = {
    type: 'fixed_yield' as 'fixed_yield',
    status: 'created' as 'created',
    opened_at: opened_at.getTime().toString(),
    closed_at: closed_at.getTime().toString(),
    address: vaultData.address as string,
    strategy_address: vaultData.address as string,
    asset_address: vaultData.asset_address as string,
  };

  return supabase.from('vaults').insert([dbData]).select();
};
