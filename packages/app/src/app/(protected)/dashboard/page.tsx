import { cookies } from 'next/headers';

import { createClient } from '@/clients/supabase.server';

import { accountStatus, mockTokenAddress } from '@/app/(protected)/dashboard/actions';
import { Lending } from '@/app/(protected)/dashboard/lending-new';

export default async function Dashboard() {
  const supabase = createClient(cookies());
  const { data: auth } = await supabase.auth.getUser();

  const account = await accountStatus();
  const tokenAddress = await mockTokenAddress();

  return <Lending status={account.status} email={auth.user?.email} mockTokenAddress={tokenAddress} />;
}
