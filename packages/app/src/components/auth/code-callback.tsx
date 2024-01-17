import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';

import { createClient } from '@/clients/supabase.server';

import { CodeCallbackRedirect } from '@/components/auth/code-callback-redirect';

import { Routes } from '@/utils/routes';

export default async function CodeCallback({ searchParams }: { searchParams: { code?: string } }) {
  if (!searchParams.code) return redirect(Routes.LOGIN);

  const supabase = createClient(cookies());
  const { data } = await supabase.auth.exchangeCodeForSession(searchParams.code);

  return (
    <CodeCallbackRedirect
      access_token={data.session?.access_token ?? ''}
      refresh_token={data.session?.refresh_token ?? ''}
    />
  );
}
