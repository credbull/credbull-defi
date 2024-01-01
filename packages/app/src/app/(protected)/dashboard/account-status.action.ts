'use server';

import { cookies } from 'next/headers';

import { createClient as createCredbull } from '@/clients/credbull-api.client';
import { createClient as createSuabase } from '@/clients/supabase.server';

export const accountStatus = async () => {
  const supabase = createSuabase(cookies());
  const credbullApi = createCredbull(supabase);

  return credbullApi.accountStatus();
};
