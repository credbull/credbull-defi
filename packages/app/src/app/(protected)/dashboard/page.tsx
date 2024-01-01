import { cookies } from 'next/headers';

import { createClient } from '@/clients/supabase.server';

import { accountStatus } from '@/app/(protected)/dashboard/account-status.action';

export default async function Dashboard() {
  const supabase = createClient(cookies());
  const { data: auth } = await supabase.auth.getUser();

  const account = await accountStatus();

  return (
    <div>
      Hey, {auth.user?.email}! You are {account.status}
    </div>
  );
}
