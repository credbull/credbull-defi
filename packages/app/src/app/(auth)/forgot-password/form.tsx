'use client';

import { LoadingOverlay } from '@mantine/core';
import { useForgotPassword, useNotification } from '@refinedev/core';
import { AuthPage } from '@refinedev/mantine';
import { useState } from 'react';

export function ForgotPasswordForm() {
  const [visible, setVisible] = useState(false);
  const { mutateAsync } = useForgotPassword();
  const { open } = useNotification();

  return (
    <>
      <div style={{ width: 400 }}>
        <LoadingOverlay visible={visible} overlayBlur={2} />
      </div>

      <AuthPage
        title="Credbull DeFI"
        type="forgotPassword"
        formProps={{
          onSubmit: async (values) => {
            setVisible(true);
            const { success, error } = await mutateAsync(values);
            setVisible(false);

            if (error) open?.({ message: error.message, type: 'error' });
            if (success) open?.({ message: 'Check your email for a password reset link.', type: 'success' });
          },
        }}
      />
    </>
  );
}
