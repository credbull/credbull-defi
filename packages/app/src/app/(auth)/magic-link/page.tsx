import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';

import { createClient } from '@/clients/supabase.server';

import { Routes } from '@/utils/routes';

import { MagicLinkRedirect } from '@/app/(auth)/magic-link/redirect';

export default async function MagicLink({ searchParams }: { searchParams: { code?: string } }) {
  if (!searchParams.code) return redirect(Routes.LOGIN);

  const supabase = createClient(cookies());
  const { data } = await supabase.auth.exchangeCodeForSession(searchParams.code);

  return (
    <MagicLinkRedirect
      access_token={data.session?.access_token ?? ''}
      refresh_token={data.session?.refresh_token ?? ''}
    />
  );
}
