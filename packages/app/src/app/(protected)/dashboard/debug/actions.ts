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
  const supabase = createSuabase(cookies());

  const opened_at = new Date(vaultData.opened_at * 1000);
  const closed_at = new Date(vaultData.closed_at * 1000);

  const dbData = {
    type: 'fixed_yield' as 'fixed_yield',
    status: 'ready' as 'ready',
    opened_at: opened_at.toISOString(),
    closed_at: closed_at.toISOString(),
    address: vaultData.address as string,
    strategy_address: vaultData.address as string,
    asset_address: vaultData.asset_address as string,
  };

  await supabase.from('vaults').insert([dbData]).select();
};
