import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';

import { createClient } from '@/clients/supabase.server';

import { Routes } from '@/utils/routes';

import { UpdatePasswordForm } from '@/app/(auth)/update-password/form';

export default async function UpdatePassword({ searchParams }: { searchParams: { code?: string } }) {
  if (!searchParams.code) return redirect(Routes.LOGIN);

  const supabase = createClient(cookies());
  const { data } = await supabase.auth.exchangeCodeForSession(searchParams.code);

  return (
    <UpdatePasswordForm
      access_token={data.session?.access_token ?? ''}
      refresh_token={data.session?.refresh_token ?? ''}
    />
  );
}
