'use client';

import { AuthPage } from '@refinedev/mantine';
import { useEffect } from 'react';

import { supabase } from '@/clients/supabase.client';

export function UpdatePasswordForm(props: { access_token: string; refresh_token: string }) {
  useEffect(() => {
    supabase.auth.setSession(props).then();
  }, [props]);

  return <AuthPage title="Credbull DeFI" type="updatePassword" />;
}
