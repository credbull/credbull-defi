'use server';

import { cookies } from 'next/headers';

import { createClient as createCredbull } from '@/clients/credbull-api.client';
import { createClient as createSupabase } from '@/clients/supabase.server';

export const whitelistAddress = async (address: string) => {
  const supabase = createSupabase(cookies());
  const credbullApi = createCredbull(supabase);

  const auth = await supabase.auth.getSession();
  const user_id = auth.data.session!.user.id;

  return credbullApi.whitelistAddress({ address, user_id });
};
