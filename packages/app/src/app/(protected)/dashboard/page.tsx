import { cookies } from 'next/headers';

import { createClient } from '@/clients/supabase.server';

import { accountStatus } from '@/app/(protected)/dashboard/account-status.action';
import { Lending } from '@/app/(protected)/dashboard/lending';

export default async function Dashboard() {
  const supabase = createClient(cookies());
  const { data: auth } = await supabase.auth.getUser();

  const account = await accountStatus();

  return <Lending status={account.status} email={auth.user?.email} />;
}
