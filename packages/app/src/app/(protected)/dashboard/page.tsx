import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';

import { createClient } from '@/clients/supabase.server';

import { Routes } from '@/utils/routes';

export default async function Dashboard() {
  const supabase = createClient(cookies());
  const { data: auth } = await supabase.auth.getUser();

  const signOut = async () => {
    'use server';
    const supabase = createClient(cookies());
    await supabase.auth.signOut();
    redirect(Routes.HOME);
  };

  return (
    <div>
      Hey, {auth.user?.email}!
      <form action={signOut}>
        <button>Logout</button>
      </form>
    </div>
  );
}
