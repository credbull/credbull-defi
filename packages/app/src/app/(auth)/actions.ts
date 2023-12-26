'use server';

import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';

import { createClient } from '@/clients/supabase.server';

import { Routes } from '@/utils/routes';

export const signOut = async () => {
  const supabase = createClient(cookies());
  await supabase.auth.signOut();
  redirect(Routes.HOME);
};
