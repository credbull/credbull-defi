'use server';

import { cookies } from 'next/headers';

import { createClient as createCredbull } from '@/clients/credbull-api.client';
import { createClient as createSuabase, createClient as createSupabase } from '@/clients/supabase.server';

export const accountStatus = async () => {
  const supabase = createSuabase(cookies());
  const credbullApi = createCredbull(supabase);

  return credbullApi.accountStatus();
};

export const linkWallet = async (message: string, signature: string, discriminator?: string) => {
  const supabase = createSuabase(cookies());
  const credbullApi = createCredbull(supabase);

  await credbullApi.linkWallet(message, signature, discriminator);
};

export const mockTokenAddress = async (): Promise<string | undefined> => {
  const admin = createSupabase(cookies(), { admin: true });
  const { data } = await admin.from('contracts_addresses').select().eq('contract_name', 'MockToken').single();

  return data?.address;
};
