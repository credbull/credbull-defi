'use server';

import { cookies } from 'next/headers';

import { createClient as createCredbull } from '@/clients/credbull-api.client';
import { createClient as createSuabase } from '@/clients/supabase.server';

export const linkWallet = async (message: string, signature: string) => {
  const supabase = createSuabase(cookies());
  const credbullApi = createCredbull(supabase);

  await credbullApi.linkWallet(message, signature);
};
