'use client';

import { LoadingOverlay } from '@mantine/core';
import { useNotification, useRegister } from '@refinedev/core';
import { AuthPage } from '@refinedev/mantine';
import { useState } from 'react';

export function RegisterForm() {
  const [visible, setVisible] = useState(false);
  const { open } = useNotification();
  const { mutateAsync } = useRegister();

  return (
    <>
      <div style={{ width: 400 }}>
        <LoadingOverlay visible={visible} overlayBlur={2} />
      </div>

      <AuthPage
        title="Credbull DeFI"
        type="register"
        formProps={{
          onSubmit: async (values) => {
            setVisible(true);
            const { success, error } = await mutateAsync(values);
            setVisible(false);

            if (error) open?.({ message: error.message, type: 'error' });
            if (success)
              open?.({
                message: 'check your email for verification link',
                description: 'Account registered successfully',
                type: 'success',
              });
          },
        }}
      />
    </>
  );
}
