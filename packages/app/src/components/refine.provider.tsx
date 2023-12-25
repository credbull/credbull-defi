'use client';

import { NotificationsProvider } from '@mantine/notifications';
import { Refine } from '@refinedev/core';
import { notificationProvider } from '@refinedev/mantine';
import routerProvider from '@refinedev/nextjs-router/app';
import { dataProvider } from '@refinedev/supabase';
import { ReactNode } from 'react';

import { supabase } from '@/clients/supabase.client';

import { provider } from '@/app/(auth)/provider';

export function RefineProvider({ children }: { children: ReactNode }) {
  return (
    <>
      <NotificationsProvider position="top-right" />
      <Refine
        notificationProvider={notificationProvider}
        dataProvider={dataProvider(supabase)}
        routerProvider={routerProvider}
        authProvider={provider}
        resources={[]}
        options={{ syncWithLocation: true }}
      >
        {children}
      </Refine>
    </>
  );
}
