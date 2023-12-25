import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import { ReactNode } from 'react';

import { createClient } from '@/clients/supabase.server';

import { Routes } from '@/utils/routes';

export default async function ProtectedLayout(props: { children: ReactNode }) {
  const supabase = createClient(cookies());
  const { data: auth } = await supabase.auth.getUser();

  if (!auth.user) redirect(Routes.LOGIN);

  return <>{props.children}</>;
}
