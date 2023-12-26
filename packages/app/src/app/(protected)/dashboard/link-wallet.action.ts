'use server';

import { cookies } from 'next/headers';
import { SiweMessage } from 'siwe';

import { createClient } from '@/clients/supabase.server';

export const linkWallet = async (message: string, signature: string) => {
  const supabase = createClient(cookies());

  const { error: authError, data: auth } = await supabase.auth.getUser();
  if (authError) throw new Error(authError.message);

  const { error: verifyError, data } = await new SiweMessage(message).verify({ signature });
  if (verifyError) throw new Error('Failed to verify message');

  await supabase.from('user_wallets').insert({
    user_id: auth.user?.id,
    address: data.address,
  });
};
