'use client';

import { LoadingOverlay } from '@mantine/core';
import { useNotification, useUpdatePassword } from '@refinedev/core';
import { AuthPage } from '@refinedev/mantine';
import { useEffect, useState } from 'react';

import { supabase } from '@/clients/supabase.client';

export function UpdatePasswordForm(props: { access_token: string; refresh_token: string }) {
  const [visible, setVisible] = useState(false);
  const { open } = useNotification();
  const { mutateAsync } = useUpdatePassword();

  useEffect(() => {
    supabase.auth.setSession(props).then();
  }, [props]);

  return (
    <>
      <div style={{ width: 400 }}>
        <LoadingOverlay visible={visible} overlayBlur={2} />
      </div>

      <AuthPage
        title="Credbull DeFI"
        type="updatePassword"
        formProps={{
          onSubmit: async (values) => {
            setVisible(true);
            const { success, error } = await mutateAsync(values);
            setVisible(false);

            if (error) open?.({ message: error.message, type: 'error' });
            if (success) open?.({ message: 'Password updated successfully', type: 'success' });
          },
        }}
      />
    </>
  );
}
