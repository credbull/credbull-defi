import { cookies } from 'next/headers';

import { createClient } from '@/clients/supabase.server';

export default async function Dashboard() {
  const supabase = createClient(cookies());
  const { data: auth } = await supabase.auth.getUser();

  return <div>Hey, {auth.user?.email}!</div>;
}
