'use client';

import { useRouter } from 'next/navigation';
import { useEffect } from 'react';

import { supabase } from '@/clients/supabase.client';

import { Routes } from '@/utils/routes';

export function MagicLinkRedirect(props: { access_token: string; refresh_token: string }) {
  const router = useRouter();

  useEffect(() => {
    supabase.auth.setSession(props).then(() => router.replace(Routes.DASHBOARD));
  }, [props, router]);

  return null;
}
